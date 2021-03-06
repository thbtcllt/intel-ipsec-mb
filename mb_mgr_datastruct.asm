;;
;; Copyright (c) 2012-2017, Intel Corporation
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:
;;
;;     * Redistributions of source code must retain the above copyright notice,
;;       this list of conditions and the following disclaimer.
;;     * Redistributions in binary form must reproduce the above copyright
;;       notice, this list of conditions and the following disclaimer in the
;;       documentation and/or other materials provided with the distribution.
;;     * Neither the name of Intel Corporation nor the names of its contributors
;;       may be used to endorse or promote products derived from this software
;;       without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;

%include "datastruct.asm"
%include "constants.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define MAX_AES_JOBS		128

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Define AES_ARGS_X8 and AES Out of Order Data Structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; AES_ARGS_X8
;;	name		size	align
FIELD	_aesarg_in,	8*8,	8	; array of 8 pointers to in text
FIELD	_aesarg_out,	8*8,	8	; array of 8 pointers to out text
FIELD	_aesarg_keys,	8*8,	8	; array of 8 pointers to keys
FIELD	_aesarg_IV,	16*8,	32	; array of 8 128-bit IV's
END_FIELDS
%assign _AES_ARGS_X8_size	_FIELD_OFFSET
%assign _AES_ARGS_X8_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; MB_MGR_AES_OOO
;;	name		size	align
FIELD	_aes_args,	_AES_ARGS_X8_size, _AES_ARGS_X8_align
FIELD	_aes_lens,	16,	16
FIELD	_aes_unused_lanes, 8,	8
FIELD	_aes_job_in_lane, 8*8,	8
END_FIELDS
%assign _MB_MGR_AES_OOO_size	_FIELD_OFFSET
%assign _MB_MGR_AES_OOO_align	_STRUCT_ALIGN

_aes_args_in	equ	_aes_args + _aesarg_in
_aes_args_out	equ	_aes_args + _aesarg_out
_aes_args_keys	equ	_aes_args + _aesarg_keys
_aes_args_IV	equ	_aes_args + _aesarg_IV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Define XCBC Out of Order Data Structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; AES_XCBC_ARGS_X8
;;	name			size	align
FIELD	_aesxcbcarg_in,		8*8,	8	; array of 8 pointers to in text
FIELD	_aesxcbcarg_keys,	8*8,	8	; array of 8 pointers to keys
FIELD	_aesxcbcarg_ICV,	16*8,	32	; array of 8 128-bit ICV's
END_FIELDS
%assign _AES_XCBC_ARGS_X8_size	_FIELD_OFFSET
%assign _AES_XCBC_ARGS_X8_align	_STRUCT_ALIGN

START_FIELDS	; XCBC_LANE_DATA
;;;	name		size	align
FIELD	_xcbc_final_block,	2*16,	32	; final block with padding
FIELD	_xcbc_job_in_lane,	8,	8	; pointer to job object
FIELD	_xcbc_final_done,	8,	8	; offset to start of data
END_FIELDS
%assign _XCBC_LANE_DATA_size	_FIELD_OFFSET
%assign	_XCBC_LANE_DATA_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; MB_MGR_AES_XCBC_OOO
;;	name		size	align
FIELD	_aes_xcbc_args,	_AES_XCBC_ARGS_X8_size, _AES_XCBC_ARGS_X8_align
FIELD	_aes_xcbc_lens,		16,	16
FIELD	_aes_xcbc_unused_lanes, 8,	8
FIELD	_aes_xcbc_ldata, _XCBC_LANE_DATA_size*8, _XCBC_LANE_DATA_align
END_FIELDS
%assign _MB_MGR_AES_XCBC_OOO_size	_FIELD_OFFSET
%assign _MB_MGR_AES_XCBC_OOO_align	_STRUCT_ALIGN

_aes_xcbc_args_in	equ	_aes_xcbc_args + _aesxcbcarg_in
_aes_xcbc_args_keys	equ	_aes_xcbc_args + _aesxcbcarg_keys
_aes_xcbc_args_ICV	equ	_aes_xcbc_args + _aesxcbcarg_ICV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Define HMAC Out Of Order Data Structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; HMAC_SHA1_LANE_DATA
;;;	name		size	align
FIELD	_extra_block,	2*64+8,	32	; final block with padding
FIELD	_job_in_lane,	8,	8	; pointer to job object
FIELD	_outer_block,	64,	1	; block containing hash
FIELD	_outer_done,	4,	4	; boolean flag
FIELD	_extra_blocks,	4,	4	; num extra blocks (1 or 2)
FIELD	_size_offset,	4,	4	; offset in extra_block to start of size
FIELD	_start_offset,	4,	4	; offset to start of data
END_FIELDS

%assign _HMAC_SHA1_LANE_DATA_size	_FIELD_OFFSET
%assign	_HMAC_SHA1_LANE_DATA_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; SHA512_LANE_DATA
;;;	name		size	align
FIELD	_extra_block_sha512,	2* SHA512_BLK_SZ + 16,	32	; final block with padding, alignment 16 to read in XMM chunks
FIELD	_outer_block_sha512,	SHA512_BLK_SZ,	        1	; block containing hash
FIELD	_job_in_lane_sha512,	8,	                8	; pointer to job object
FIELD	_outer_done_sha512,	4,	                4	; boolean flag
FIELD	_extra_blocks_sha512,	4,	                4	; num extra blocks (1 or 2)
FIELD	_size_offset_sha512,	4,	                4	; offset in extra_block to start of size
FIELD	_start_offset_sha512,	4,	                4	; offset to start of data
END_FIELDS
%assign _SHA512_LANE_DATA_size	_FIELD_OFFSET
%assign	_SHA512_LANE_DATA_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; SHA1_ARGS
;;;	name		size	                align
FIELD	_digest,	SHA1_DIGEST_SIZE,	32	; transposed digest
FIELD	_data_ptr_sha1, PTR_SZ*MAX_SHA1_LANES,	8	; array of pointers to data
END_FIELDS
%assign _SHA1_ARGS_size		_FIELD_OFFSET
%assign _SHA1_ARGS_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; MB_MGR_HMAC_SHA_1_OOO
;;;	name		size	align
FIELD	_args,		_SHA1_ARGS_size, _SHA1_ARGS_align
FIELD	_lens,		32,	32
FIELD	_unused_lanes,	8,	8
FIELD	_ldata,		_HMAC_SHA1_LANE_DATA_size*MAX_SHA1_LANES, _HMAC_SHA1_LANE_DATA_align
FIELD   _num_lanes_inuse_sha1, 4,     4
END_FIELDS
%assign _MB_MGR_HMAC_SHA_1_OOO_size	_FIELD_OFFSET
%assign _MB_MGR_HMAC_SHA_1_OOO_align	_STRUCT_ALIGN

_args_digest	equ	_args + _digest
_args_data_ptr	equ	_args + _data_ptr_sha1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; SHA256_ARGS
;;;	name		        size	                        align
FIELD	_digest_sha256,	        SHA256_DIGEST_SIZE,	        32	; transposed digest
FIELD	_data_ptr_sha256,	PTR_SZ*MAX_SHA256_LANES,	8	; array of pointers to data
END_FIELDS
%assign _SHA256_ARGS_size	_FIELD_OFFSET
%assign _SHA256_ARGS_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; MB_MGR_HMAC_SHA_256_OOO
;;;	name		size	align
FIELD	_args_sha256,		 _SHA256_ARGS_size, _SHA256_ARGS_align
FIELD	_lens_sha256,		 16*2,	16
FIELD	_unused_lanes_sha256,	 8,	8
FIELD	_ldata_sha256,		 _HMAC_SHA1_LANE_DATA_size * MAX_SHA256_LANES, _HMAC_SHA1_LANE_DATA_align
FIELD   _num_lanes_inuse_sha256, 4,     4
END_FIELDS
%assign _MB_MGR_HMAC_SHA_256_OOO_size	_FIELD_OFFSET
%assign _MB_MGR_HMAC_SHA_256_OOO_align	_STRUCT_ALIGN

_args_digest_sha256	equ	_args_sha256 + _digest_sha256
_args_data_ptr_sha256	equ	_args_sha256 + _data_ptr_sha256

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Define HMAC SHA512 Out Of Order Data Structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; SHA512_ARGS
;;;	name		        size	                        align
FIELD	_digest_sha512,	        SHA512_DIGEST_SIZE,	        32      ; transposed digest. 2 lanes, 8 digest words, each 8 bytes long
FIELD	_data_ptr_sha512,	MAX_SHA512_LANES * PTR_SZ,	8	; array of pointers to data
END_FIELDS
%assign _SHA512_ARGS_size	_FIELD_OFFSET
%assign _SHA512_ARGS_align	_STRUCT_ALIGN


;; ---------------------------------------
START_FIELDS	; MB_MGR_HMAC_SHA512_OOO
;;;	name	         	size             	align
FIELD	_args_sha512,		_SHA512_ARGS_size,  _SHA512_ARGS_align
FIELD	_lens_sha512,		16,	16
FIELD	_unused_lanes_sha512,	8,	                8
FIELD	_ldata_sha512,		_SHA512_LANE_DATA_size * MAX_SHA512_LANES, _SHA512_LANE_DATA_align
END_FIELDS
%assign _MB_MGR_HMAC_SHA_512_OOO_size	_FIELD_OFFSET
%assign _MB_MGR_HMAC_SHA_512_OOO_align	_STRUCT_ALIGN

_args_digest_sha512	equ	_args_sha512 + _digest_sha512
_args_data_ptr_sha512	equ	_args_sha512 + _data_ptr_sha512



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Define HMAC MD5 Out Of Order Data Structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; MD5_ARGS
;;;	name		size	                align
FIELD	_digest_md5,	MD5_DIGEST_SIZE,	32	; transposed digest
FIELD	_data_ptr_md5,	MAX_MD5_LANES*PTR_SZ,	8	; array of pointers to data
END_FIELDS
%assign _MD5_ARGS_size	_FIELD_OFFSET
%assign _MD5_ARGS_align	_STRUCT_ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START_FIELDS	; MB_MGR_HMAC_MD5_OOO
;;;	name		size	align
FIELD	_args_md5,	_MD5_ARGS_size, _MD5_ARGS_align
FIELD	_lens_md5,	MAX_MD5_LANES*2,	16
FIELD	_unused_lanes_md5, 8,	8
FIELD	_ldata_md5,	_HMAC_SHA1_LANE_DATA_size * MAX_MD5_LANES, _HMAC_SHA1_LANE_DATA_align
FIELD   _num_lanes_inuse_md5, 4,     8
END_FIELDS
%assign _MB_MGR_HMAC_MD5_OOO_size	_FIELD_OFFSET
%assign _MB_MGR_HMAC_MD5_OOO_align	_STRUCT_ALIGN

_args_digest_md5	equ	_args_md5 + _digest_md5
_args_data_ptr_md5	equ	_args_md5 + _data_ptr_md5
