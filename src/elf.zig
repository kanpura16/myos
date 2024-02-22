pub const Elf64Hdr = packed struct {
    e_ident: u128,
    e_type: u16,
    e_machine: u16,
    e_version: u32,
    e_entry: u64,
    e_phoff: u64,
    e_shoff: u64,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,
};

pub const Elf64Phdr = packed struct {
    p_type: PType,
    p_flags: u32,
    p_offset: u64,
    p_vaddr: u64,
    p_paddr: u64,
    p_filesz: u64,
    p_memsz: u64,
    p_align: u64,
};

const PType = enum(u32) {
    PT_NULL = 0,
    PT_LOAD = 1,
    PT_DYNAMIC = 2,
    PT_INTERP = 3,
    PT_NOTE = 4,
    PT_SHLID = 5,
    PT_PHDR = 6,
    PT_TLS = 7,
    PT_LOOS = 0x6000_0000,
    PT_HIOS = 0x6FFF_FFFF,
    PT_LOPROC = 0x7000_0000,
    PT_HIPROC = 0x7FFF_FFFF,
};
