#include <Windows.h>

typedef struct _RSAPUBKEYBLOB {
    PUBLICKEYSTRUC  hdr;
    RSAPUBKEY pubkey;
    BYTE modulus[0x100];
} RSAPUBKEYBLOB;

typedef struct _RSAPRIVKEYBLOB {
    PUBLICKEYSTRUC hdr;
    RSAPUBKEY pubkey;
    BYTE modulus[0x100];
    BYTE prime1[0x80];
    BYTE prime2[0x80];
    BYTE exp1[0x80];
    BYTE exp2[0x80];
    BYTE coeff[0x80];
    BYTE priv_exp[0x100];
} RSAPRIVKEYBLOB;

typedef struct _SIMPLEKEYBLOB {
    PUBLICKEYSTRUC hdr;
    ALG_ID algid;
    BYTE key[0x100];
} SIMPLEKEYBLOB;

typedef struct _RANGE_INFO {
    LONGLONG offset;
    ULONG bytes;
} RANGE_INFO;

#include <PshPack1.h>

typedef struct _RESHDR_DISK_SHORT {
    ULONGLONG size_in_wim : 56;
    ULONGLONG flags : 8;
    LONGLONG offset_in_wim;
    LONGLONG original_size;
} RESHDR_DISK_SHORT;

#include <PopPack.h>

#define WIM_TAG 0x0000004d4957534dULL // "MSWIM\0\0\0"
#define WIM_HEADER_SIZE 208

#define FLAG_HEADER_RESERVED            0x00000001
#define FLAG_HEADER_COMPRESSION         0x00000002
#define FLAG_HEADER_READONLY            0x00000004
#define FLAG_HEADER_SPANNED             0x00000008
#define FLAG_HEADER_RESOURCE_ONLY       0x00000010
#define FLAG_HEADER_METADATA_ONLY       0x00000020
#define FLAG_HEADER_WRITE_IN_PROGRESS   0x00000040
#define FLAG_HEADER_RP_FIX              0x00000080 // reparse point fixup
#define FLAG_HEADER_COMPRESS_RESERVED   0x00010000
#define FLAG_HEADER_COMPRESS_XPRESS     0x00020000
#define FLAG_HEADER_COMPRESS_LZX        0x00040000
#define FLAG_HEADER_COMPRESS_LZMS       0x00080000

#define RESHDR_FLAG_FREE            0x01
#define RESHDR_FLAG_METADATA        0x02
#define RESHDR_FLAG_COMPRESSED      0x04
#define RESHDR_FLAG_SPANNED         0x08

#define SWAP(t, a, b) { t temp = (a); (a) = (b); (b) = temp; }

typedef struct _WIM_HDR {
    ULONGLONG wim_tag; // "MSWIM\0\0\0"
    DWORD hdr_size;
    DWORD wim_version;
    DWORD wim_flags;
    DWORD chunk_size;
    GUID wim_guid;
    WORD part_number;
    WORD total_parts;
    DWORD image_count;
    RESHDR_DISK_SHORT lookup_table;
    RESHDR_DISK_SHORT xml_data;
    RESHDR_DISK_SHORT boot_metadata;
    DWORD boot_index;
    RESHDR_DISK_SHORT integrity_table;
    BYTE unused[60];
} WIM_HDR;

typedef struct _WIM_XML_INFO {
    ULONGLONG size;
    LONGLONG offset;
    WCHAR *data;
} WIM_XML_INFO;

#define SHA1_HASH_SIZE 20

#pragma warning( push )
#pragma warning( disable:4200 )
typedef struct _WIM_HASH_TABLE {
	DWORD size;
	DWORD num_elements;
	DWORD chunk_size;
	BYTE hash_list[][SHA1_HASH_SIZE];
} WIM_HASH_TABLE;
#pragma warning( pop )

typedef struct _WIM_INFO {
    FILE *wim_file;
    WIM_HDR hdr;
    WIM_XML_INFO xml;
    RSAPRIVKEYBLOB crypto_key;
    SIMPLEKEYBLOB session_key;
    int num_encrypted_ranges;
    RANGE_INFO *encrypted_ranges;
} WIM_INFO;
