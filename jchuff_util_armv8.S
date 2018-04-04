#ifdef USE_NEON

#if !defined(__APPLE__)

#define ENTRY(name) \
.globl name; \
.hidden name; \
.type name, @function; \
name:

#define ENDPROC(name) \
.size name, .-name

#else

#define ENTRY(name) \
.globl _ ## name; \
.private_extern _ ## name; \
_ ## name:

#define ENDPROC(name)

#endif

.align	3
.shuf_mask:
.byte	60, 52, 44, 36, 28, 20, 12, 4


###############################################################################
# {uint64_t EOB, uint64_t Z_MASK} AC_refine_util_64(short *block, int *natural_order, short *res, int al);

ENTRY(AC_refine_util_64)

    # Load and deintreleave the block
    ld2 {v0.16b - v1.16b}, [x0], 32
    ld2 {v16.16b - v17.16b}, [x0], 32
    ld2 {v18.16b - v19.16b}, [x0], 32
    ld2 {v20.16b - v21.16b}, [x0]

    mov v4.16b, v1.16b
    mov v5.16b, v17.16b
    mov v6.16b, v19.16b
    mov v7.16b, v21.16b
    mov v1.16b, v16.16b
    mov v2.16b, v18.16b
    mov v3.16b, v20.16b
    # Load the order
    ld4 {v16.16b - v19.16b}, [x1], 64
    ld4 {v17.16b - v20.16b}, [x1], 64
    ld4 {v18.16b - v21.16b}, [x1], 64
    ld4 {v19.16b - v22.16b}, [x1]
    # Table lookup, LSB and MSB independently
    tbl v20.16b, {v0.16b - v3.16b}, v16.16b
    tbl v16.16b, {v4.16b - v7.16b}, v16.16b
    tbl v21.16b, {v0.16b - v3.16b}, v17.16b
    tbl v17.16b, {v4.16b - v7.16b}, v17.16b
    tbl v22.16b, {v0.16b - v3.16b}, v18.16b
    tbl v18.16b, {v4.16b - v7.16b}, v18.16b
    tbl v23.16b, {v0.16b - v3.16b}, v19.16b
    tbl v19.16b, {v4.16b - v7.16b}, v19.16b
    # Interleave MSB and LSB back
    zip1 v0.16b, v20.16b, v16.16b
    zip2 v1.16b, v20.16b, v16.16b
    zip1 v2.16b, v21.16b, v17.16b
    zip2 v3.16b, v21.16b, v17.16b
    zip1 v4.16b, v22.16b, v18.16b
    zip2 v5.16b, v22.16b, v18.16b
    zip1 v6.16b, v23.16b, v19.16b
    zip2 v7.16b, v23.16b, v19.16b
    # -Al
    neg w3, w3
    dup v16.8h, w3
    # Absolute then shift by Al
    abs v0.8h, v0.8h
    sshl v0.8h, v0.8h, v16.8h
    abs v1.8h, v1.8h
    sshl v1.8h, v1.8h, v16.8h
    abs v2.8h, v2.8h
    sshl v2.8h, v2.8h, v16.8h
    abs v3.8h, v3.8h
    sshl v3.8h, v3.8h, v16.8h
    abs v4.8h, v4.8h
    sshl v4.8h, v4.8h, v16.8h
    abs v5.8h, v5.8h
    sshl v5.8h, v5.8h, v16.8h
    abs v6.8h, v6.8h
    sshl v6.8h, v6.8h, v16.8h
    abs v7.8h, v7.8h
    sshl v7.8h, v7.8h, v16.8h
    # Store
    st1 {v0.16b - v3.16b}, [x2], 64
    st1 {v4.16b - v7.16b}, [x2]
    # Constant 1
    movi v16.8h, 0x1
    # Compare with 0 for zero mask
    cmeq v17.8h, v0.8h, #0
    cmeq v18.8h, v1.8h, #0
    cmeq v19.8h, v2.8h, #0
    cmeq v20.8h, v3.8h, #0
    cmeq v21.8h, v4.8h, #0
    cmeq v22.8h, v5.8h, #0
    cmeq v23.8h, v6.8h, #0
    cmeq v24.8h, v7.8h, #0
    # Compare with 1 for EOB mask
    cmeq v0.8h, v0.8h, v16.8h
    cmeq v1.8h, v1.8h, v16.8h
    cmeq v2.8h, v2.8h, v16.8h
    cmeq v3.8h, v3.8h, v16.8h
    cmeq v4.8h, v4.8h, v16.8h
    cmeq v5.8h, v5.8h, v16.8h
    cmeq v6.8h, v6.8h, v16.8h
    cmeq v7.8h, v7.8h, v16.8h
    # For both masks -> keep only one byte for each comparison
    uzp1 v0.16b, v0.16b, v1.16b
    uzp1 v1.16b, v2.16b, v3.16b
    uzp1 v2.16b, v4.16b, v5.16b
    uzp1 v3.16b, v6.16b, v7.16b

    uzp1 v17.16b, v17.16b, v18.16b
    uzp1 v18.16b, v19.16b, v20.16b
    uzp1 v19.16b, v21.16b, v22.16b
    uzp1 v20.16b, v23.16b, v24.16b
    # Shift left and insert (int16) to get a single bit from even to odd bytes
    sli v0.8h, v0.8h, 15
    sli v1.8h, v1.8h, 15
    sli v2.8h, v2.8h, 15
    sli v3.8h, v3.8h, 15

    sli v17.8h, v17.8h, 15
    sli v18.8h, v18.8h, 15
    sli v19.8h, v19.8h, 15
    sli v20.8h, v20.8h, 15
    # Shift right and insert (int32) to get two bits from off to even indices
    sri v0.4s, v0.4s, 18
    sri v1.4s, v1.4s, 18
    sri v2.4s, v2.4s, 18
    sri v3.4s, v3.4s, 18

    sri v17.4s, v17.4s, 18
    sri v18.4s, v18.4s, 18
    sri v19.4s, v19.4s, 18
    sri v20.4s, v20.4s, 18
    # Regular shift right to align the 4 bits at the bottom of each int64
    ushr v0.2d, v0.2d, 12
    ushr v1.2d, v1.2d, 12
    ushr v2.2d, v2.2d, 12
    ushr v3.2d, v3.2d, 12

    ushr v17.2d, v17.2d, 12
    ushr v18.2d, v18.2d, 12
    ushr v19.2d, v19.2d, 12
    ushr v20.2d, v20.2d, 12
    # Shift left and insert (int64) to combine all 8 bits into one byte
    sli v0.2d, v0.2d, 36
    sli v1.2d, v1.2d, 36
    sli v2.2d, v2.2d, 36
    sli v3.2d, v3.2d, 36

    sli v17.2d, v17.2d, 36
    sli v18.2d, v18.2d, 36
    sli v19.2d, v19.2d, 36
    sli v20.2d, v20.2d, 36
    # Combine all the byte mask insto a bit 64-bit mask for EOB and zero masks
    ldr d4, .shuf_mask
    tbl v5.8b, {v0.16b - v3.16b}, v4.8b
    tbl v6.8b, {v17.16b - v20.16b}, v4.8b
    # Extract lanes
    mov x0, v5.d[0]
    mov x1, v6.d[0]
    # Compute EOB
    rbit x0, x0
    clz x0, x0
    mov x2, 64
    sub x0, x2, x0
    # Not of zero mask (so 1 bits indecates non-zeroes)
    mvn x1, x1
    ret

ENDPROC(AC_refine_util_64)

###############################################################################
# uint64_t AC_first_util_64(short *block, int *natural_order, short *t0, short *t1, int al);
ENTRY(AC_first_util_64)

    # Load the block
    ld2 {v0.16b - v1.16b}, [x0], 32
    ld2 {v16.16b - v17.16b}, [x0], 32
    ld2 {v18.16b - v19.16b}, [x0], 32
    ld2 {v20.16b - v21.16b}, [x0]

    mov v4.16b, v1.16b
    mov v5.16b, v17.16b
    mov v6.16b, v19.16b
    mov v7.16b, v21.16b
    mov v1.16b, v16.16b
    mov v2.16b, v18.16b
    mov v3.16b, v20.16b

    # Load the order
    ld4 {v16.16b - v19.16b}, [x1], 64
    ld4 {v17.16b - v20.16b}, [x1], 64
    ld4 {v18.16b - v21.16b}, [x1], 64
    ld4 {v19.16b - v22.16b}, [x1]
    # Table lookup, LSB and MSB independently
    tbl v20.16b, {v0.16b - v3.16b}, v16.16b
    tbl v16.16b, {v4.16b - v7.16b}, v16.16b
    tbl v21.16b, {v0.16b - v3.16b}, v17.16b
    tbl v17.16b, {v4.16b - v7.16b}, v17.16b
    tbl v22.16b, {v0.16b - v3.16b}, v18.16b
    tbl v18.16b, {v4.16b - v7.16b}, v18.16b
    tbl v23.16b, {v0.16b - v3.16b}, v19.16b
    tbl v19.16b, {v4.16b - v7.16b}, v19.16b
    # Interleave MSB and LSB back
    zip1 v0.16b, v20.16b, v16.16b
    zip2 v1.16b, v20.16b, v16.16b
    zip1 v2.16b, v21.16b, v17.16b
    zip2 v3.16b, v21.16b, v17.16b
    zip1 v4.16b, v22.16b, v18.16b
    zip2 v5.16b, v22.16b, v18.16b
    zip1 v6.16b, v23.16b, v19.16b
    zip2 v7.16b, v23.16b, v19.16b
    # -Al
    neg w4, w4
    dup v24.8h, w4
    # Compare with 0 to get negative mask
    cmge v16.8h, v0.8h, #0
    # Absolute value and shift by Al
    abs v0.8h, v0.8h
    sshl v0.8h, v0.8h, v24.8h
    cmge v17.8h, v1.8h, #0
    abs v1.8h, v1.8h
    sshl v1.8h, v1.8h, v24.8h
    cmge v18.8h, v2.8h, #0
    abs v2.8h, v2.8h
    sshl v2.8h, v2.8h, v24.8h
    cmge v19.8h, v3.8h, #0
    abs v3.8h, v3.8h
    sshl v3.8h, v3.8h, v24.8h
    cmge v20.8h, v4.8h, #0
    abs v4.8h, v4.8h
    sshl v4.8h, v4.8h, v24.8h
    cmge v21.8h, v5.8h, #0
    abs v5.8h, v5.8h
    sshl v5.8h, v5.8h, v24.8h
    cmge v22.8h, v6.8h, #0
    abs v6.8h, v6.8h
    sshl v6.8h, v6.8h, v24.8h
    cmge v23.8h, v7.8h, #0
    abs v7.8h, v7.8h
    sshl v7.8h, v7.8h, v24.8h
    # ~
    mvn v24.16b, v0.16b
    mvn v25.16b, v1.16b
    mvn v26.16b, v2.16b
    mvn v27.16b, v3.16b
    mvn v28.16b, v4.16b
    mvn v29.16b, v5.16b
    mvn v30.16b, v6.16b
    mvn v31.16b, v7.16b
    # Select
    bsl v16.16b, v0.16b, v24.16b
    bsl v17.16b, v1.16b, v25.16b
    bsl v18.16b, v2.16b, v26.16b
    bsl v19.16b, v3.16b, v27.16b
    bsl v20.16b, v4.16b, v28.16b
    bsl v21.16b, v5.16b, v29.16b
    bsl v22.16b, v6.16b, v30.16b
    bsl v23.16b, v7.16b, v31.16b
    # Store t1
    st1 {v0.16b - v3.16b}, [x2], 64
    st1 {v4.16b - v7.16b}, [x2]
    # Store t2
    st1 {v16.16b - v19.16b}, [x3], 64
    st1 {v20.16b - v23.16b}, [x3]
    # Compute zero mask like before
    cmeq v17.8h, v0.8h, #0
    cmeq v18.8h, v1.8h, #0
    cmeq v19.8h, v2.8h, #0
    cmeq v20.8h, v3.8h, #0
    cmeq v21.8h, v4.8h, #0
    cmeq v22.8h, v5.8h, #0
    cmeq v23.8h, v6.8h, #0
    cmeq v24.8h, v7.8h, #0

    uzp1 v17.16b, v17.16b, v18.16b
    uzp1 v18.16b, v19.16b, v20.16b
    uzp1 v19.16b, v21.16b, v22.16b
    uzp1 v20.16b, v23.16b, v24.16b

    sli v17.8h, v17.8h, 15
    sli v18.8h, v18.8h, 15
    sli v19.8h, v19.8h, 15
    sli v20.8h, v20.8h, 15

    sri v17.4s, v17.4s, 18
    sri v18.4s, v18.4s, 18
    sri v19.4s, v19.4s, 18
    sri v20.4s, v20.4s, 18

    ushr v17.2d, v17.2d, 12
    ushr v18.2d, v18.2d, 12
    ushr v19.2d, v19.2d, 12
    ushr v20.2d, v20.2d, 12

    sli v17.2d, v17.2d, 36
    sli v18.2d, v18.2d, 36
    sli v19.2d, v19.2d, 36
    sli v20.2d, v20.2d, 36

    ldr d4, .shuf_mask
    tbl v6.8b, {v17.16b - v20.16b}, v4.8b

    mov x0, v6.d[0]
    mvn x0, x0
    ret

ENDPROC(AC_first_util_64)

#endif
