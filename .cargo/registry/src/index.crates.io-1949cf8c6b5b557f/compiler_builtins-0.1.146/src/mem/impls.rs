// In C and Rust it is UB to read or write to usize::MAX because if an allocation extends to the
// last byte of address space (there must be an allocation to do the read or write), in C computing
// its one-past-the-end pointer would be equal to NULL and in Rust computing the address of a
// trailing ZST member with a safe place projection would wrap (place projection address computation
// is non-wrapping).
//
// However, some embedded systems have special memory at usize::MAX, and need to access that
// memory. If they do that with the intrinsics provided by compiler-builtins (such as memcpy!), the
// ptr::add in these loops will wrap. And if compiler-builtins is compiled with cfg(ub_checks),
// this will fail a UB check at runtime.
//
// Since this scenario is UB, we are within our rights hit this check and halt execution...
// But we are also within our rights to try to make it work.
// We use wrapping_add/wrapping_sub for pointer arithmetic in this module in an attempt to support
// this use. Of course this is not a guarantee that such use will work, it just means that this
// crate doing wrapping pointer arithmetic with a method that must not wrap won't be the problem if
// something does go wrong at runtime.
use core::intrinsics::likely;

const WORD_SIZE: usize = core::mem::size_of::<usize>();
const WORD_MASK: usize = WORD_SIZE - 1;

// If the number of bytes involved exceed this threshold we will opt in word-wise copy.
// The value here selected is max(2 * WORD_SIZE, 16):
// * We need at least 2 * WORD_SIZE bytes to guarantee that at least 1 word will be copied through
//   word-wise copy.
// * The word-wise copy logic needs to perform some checks so it has some small overhead.
//   ensures that even on 32-bit platforms we have copied at least 8 bytes through
//   word-wise copy so the saving of word-wise copy outweighs the fixed overhead.
const WORD_COPY_THRESHOLD: usize = if 2 * WORD_SIZE > 16 {
    2 * WORD_SIZE
} else {
    16
};

#[cfg(feature = "mem-unaligned")]
unsafe fn read_usize_unaligned(x: *const usize) -> usize {
    // Do not use `core::ptr::read_unaligned` here, since it calls `copy_nonoverlapping` which
    // is translated to memcpy in LLVM.
    let x_read = (x as *const [u8; core::mem::size_of::<usize>()]).read();
    core::mem::transmute(x_read)
}

#[inline(always)]
pub unsafe fn copy_forward(mut dest: *mut u8, mut src: *const u8, mut n: usize) {
    #[inline(always)]
    unsafe fn copy_forward_bytes(mut dest: *mut u8, mut src: *const u8, n: usize) {
        let dest_end = dest.wrapping_add(n);
        while dest < dest_end {
            *dest = *src;
            dest = dest.wrapping_add(1);
            src = src.wrapping_add(1);
        }
    }

    #[inline(always)]
    unsafe fn copy_forward_aligned_words(dest: *mut u8, src: *const u8, n: usize) {
        let mut dest_usize = dest as *mut usize;
        let mut src_usize = src as *mut usize;
        let dest_end = dest.wrapping_add(n) as *mut usize;

        while dest_usize < dest_end {
            *dest_usize = *src_usize;
            dest_usize = dest_usize.wrapping_add(1);
            src_usize = src_usize.wrapping_add(1);
        }
    }

    #[cfg(not(feature = "mem-unaligned"))]
    #[inline(always)]
    unsafe fn copy_forward_misaligned_words(dest: *mut u8, src: *const u8, n: usize) {
        let mut dest_usize = dest as *mut usize;
        let dest_end = dest.wrapping_add(n) as *mut usize;

        // Calculate the misalignment offset and shift needed to reassemble value.
        let offset = src as usize & WORD_MASK;
        let shift = offset * 8;

        // Realign src
        let mut src_aligned = (src as usize & !WORD_MASK) as *mut usize;
        // This will read (but won't use) bytes out of bound.
        // cfg needed because not all targets will have atomic loads that can be lowered
        // (e.g. BPF, MSP430), or provided by an external library (e.g. RV32I)
        #[cfg(target_has_atomic_load_store = "ptr")]
        let mut prev_word = core::intrinsics::atomic_load_unordered(src_aligned);
        #[cfg(not(target_has_atomic_load_store = "ptr"))]
        let mut prev_word = core::ptr::read_volatile(src_aligned);

        while dest_usize < dest_end {
            src_aligned = src_aligned.wrapping_add(1);
            let cur_word = *src_aligned;
            #[cfg(target_endian = "little")]
            let resembled = prev_word >> shift | cur_word << (WORD_SIZE * 8 - shift);
            #[cfg(target_endian = "big")]
            let resembled = prev_word << shift | cur_word >> (WORD_SIZE * 8 - shift);
            prev_word = cur_word;

            *dest_usize = resembled;
            dest_usize = dest_usize.wrapping_add(1);
        }
    }

    #[cfg(feature = "mem-unaligned")]
    #[inline(always)]
    unsafe fn copy_forward_misaligned_words(dest: *mut u8, src: *const u8, n: usize) {
        let mut dest_usize = dest as *mut usize;
        let mut src_usize = src as *mut usize;
        let dest_end = dest.wrapping_add(n) as *mut usize;

        while dest_usize < dest_end {
            *dest_usize = read_usize_unaligned(src_usize);
            dest_usize = dest_usize.wrapping_add(1);
            src_usize = src_usize.wrapping_add(1);
        }
    }

    if n >= WORD_COPY_THRESHOLD {
        // Align dest
        // Because of n >= 2 * WORD_SIZE, dst_misalignment < n
        let dest_misalignment = (dest as usize).wrapping_neg() & WORD_MASK;
        copy_forward_bytes(dest, src, dest_misalignment);
        dest = dest.wrapping_add(dest_misalignment);
        src = src.wrapping_add(dest_misalignment);
        n -= dest_misalignment;

        let n_words = n & !WORD_MASK;
        let src_misalignment = src as usize & WORD_MASK;
        if likely(src_misalignment == 0) {
            copy_forward_aligned_words(dest, src, n_words);
        } else {
            copy_forward_misaligned_words(dest, src, n_words);
        }
        dest = dest.wrapping_add(n_words);
        src = src.wrapping_add(n_words);
        n -= n_words;
    }
    copy_forward_bytes(dest, src, n);
}

#[inline(always)]
pub unsafe fn copy_backward(dest: *mut u8, src: *const u8, mut n: usize) {
    // The following backward copy helper functions uses the pointers past the end
    // as their inputs instead of pointers to the start!
    #[inline(always)]
    unsafe fn copy_backward_bytes(mut dest: *mut u8, mut src: *const u8, n: usize) {
        let dest_start = dest.wrapping_sub(n);
        while dest_start < dest {
            dest = dest.wrapping_sub(1);
            src = src.wrapping_sub(1);
            *dest = *src;
        }
    }

    #[inline(always)]
    unsafe fn copy_backward_aligned_words(dest: *mut u8, src: *const u8, n: usize) {
        let mut dest_usize = dest as *mut usize;
        let mut src_usize = src as *mut usize;
        let dest_start = dest.wrapping_sub(n) as *mut usize;

        while dest_start < dest_usize {
            dest_usize = dest_usize.wrapping_sub(1);
            src_usize = src_usize.wrapping_sub(1);
            *dest_usize = *src_usize;
        }
    }

    #[cfg(not(feature = "mem-unaligned"))]
    #[inline(always)]
    unsafe fn copy_backward_misaligned_words(dest: *mut u8, src: *const u8, n: usize) {
        let mut dest_usize = dest as *mut usize;
        let dest_start = dest.wrapping_sub(n) as *mut usize;

        // Calculate the misalignment offset and shift needed to reassemble value.
        let offset = src as usize & WORD_MASK;
        let shift = offset * 8;

        // Realign src_aligned
        let mut src_aligned = (src as usize & !WORD_MASK) as *mut usize;
        // This will read (but won't use) bytes out of bound.
        // cfg needed because not all targets will have atomic loads that can be lowered
        // (e.g. BPF, MSP430), or provided by an external library (e.g. RV32I)
        #[cfg(target_has_atomic_load_store = "ptr")]
        let mut prev_word = core::intrinsics::atomic_load_unordered(src_aligned);
        #[cfg(not(target_has_atomic_load_store = "ptr"))]
        let mut prev_word = core::ptr::read_volatile(src_aligned);

        while dest_start < dest_usize {
            src_aligned = src_aligned.wrapping_sub(1);
            let cur_word = *src_aligned;
            #[cfg(target_endian = "little")]
            let resembled = prev_word << (WORD_SIZE * 8 - shift) | cur_word >> shift;
            #[cfg(target_endian = "big")]
            let resembled = prev_word >> (WORD_SIZE * 8 - shift) | cur_word << shift;
            prev_word = cur_word;

            dest_usize = dest_usize.wrapping_sub(1);
            *dest_usize = resembled;
        }
    }

    #[cfg(feature = "mem-unaligned")]
    #[inline(always)]
    unsafe fn copy_backward_misaligned_words(dest: *mut u8, src: *const u8, n: usize) {
        let mut dest_usize = dest as *mut usize;
        let mut src_usize = src as *mut usize;
        let dest_start = dest.wrapping_sub(n) as *mut usize;

        while dest_start < dest_usize {
            dest_usize = dest_usize.wrapping_sub(1);
            src_usize = src_usize.wrapping_sub(1);
            *dest_usize = read_usize_unaligned(src_usize);
        }
    }

    let mut dest = dest.wrapping_add(n);
    let mut src = src.wrapping_add(n);

    if n >= WORD_COPY_THRESHOLD {
        // Align dest
        // Because of n >= 2 * WORD_SIZE, dst_misalignment < n
        let dest_misalignment = dest as usize & WORD_MASK;
        copy_backward_bytes(dest, src, dest_misalignment);
        dest = dest.wrapping_sub(dest_misalignment);
        src = src.wrapping_sub(dest_misalignment);
        n -= dest_misalignment;

        let n_words = n & !WORD_MASK;
        let src_misalignment = src as usize & WORD_MASK;
        if likely(src_misalignment == 0) {
            copy_backward_aligned_words(dest, src, n_words);
        } else {
            copy_backward_misaligned_words(dest, src, n_words);
        }
        dest = dest.wrapping_sub(n_words);
        src = src.wrapping_sub(n_words);
        n -= n_words;
    }
    copy_backward_bytes(dest, src, n);
}

#[inline(always)]
pub unsafe fn set_bytes(mut s: *mut u8, c: u8, mut n: usize) {
    #[inline(always)]
    pub unsafe fn set_bytes_bytes(mut s: *mut u8, c: u8, n: usize) {
        let end = s.wrapping_add(n);
        while s < end {
            *s = c;
            s = s.wrapping_add(1);
        }
    }

    #[inline(always)]
    pub unsafe fn set_bytes_words(s: *mut u8, c: u8, n: usize) {
        let mut broadcast = c as usize;
        let mut bits = 8;
        while bits < WORD_SIZE * 8 {
            broadcast |= broadcast << bits;
            bits *= 2;
        }

        let mut s_usize = s as *mut usize;
        let end = s.wrapping_add(n) as *mut usize;

        while s_usize < end {
            *s_usize = broadcast;
            s_usize = s_usize.wrapping_add(1);
        }
    }

    if likely(n >= WORD_COPY_THRESHOLD) {
        // Align s
        // Because of n >= 2 * WORD_SIZE, dst_misalignment < n
        let misalignment = (s as usize).wrapping_neg() & WORD_MASK;
        set_bytes_bytes(s, c, misalignment);
        s = s.wrapping_add(misalignment);
        n -= misalignment;

        let n_words = n & !WORD_MASK;
        set_bytes_words(s, c, n_words);
        s = s.wrapping_add(n_words);
        n -= n_words;
    }
    set_bytes_bytes(s, c, n);
}

#[inline(always)]
pub unsafe fn compare_bytes(s1: *const u8, s2: *const u8, n: usize) -> i32 {
    let mut i = 0;
    while i < n {
        let a = *s1.wrapping_add(i);
        let b = *s2.wrapping_add(i);
        if a != b {
            return a as i32 - b as i32;
        }
        i += 1;
    }
    0
}

#[inline(always)]
pub unsafe fn c_string_length(mut s: *const core::ffi::c_char) -> usize {
    let mut n = 0;
    while *s != 0 {
        n += 1;
        s = s.wrapping_add(1);
    }
    n
}
