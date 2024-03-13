pub var frame_buf_conf: FrameBufConf = undefined;

pub const FrameBufConf = struct {
    frame_buf: [*]volatile u8,
    horizon_res: u32,
    vertical_res: u32,
    pixels_per_row: u32,
    pixel_format: PixelFormat,

    const PixelFormat = enum {
        RGB8BitPerColor,
        BGR8BitPerColor,
    };
};

pub const MemoryMap = struct {
    map: [*]MemoryDescriptor,
    map_size: usize,
    desc_size: usize,

    pub const MemoryDescriptor = extern struct {
        type: MemoryType,
        physical_start: u64,
        virtual_start: u64,
        num_pages: u64,
        attribute: u64,

        pub const MemoryType = enum(c_uint) {
            ReservedMemoryType,
            LoaderCode,
            LoaderData,
            BootServicesCode,
            BootServicesData,
            RuntimeServicesCode,
            RuntimeServicesData,
            ConventionalMemory,
            UnusableMemory,
            ACPIReclaimMemory,
            ACPIMemoryNVS,
            MemoryMappedIO,
            MemoryMappedIOPortSpace,
            PalCode,
            PersistentMemory,
            MaxMemoryType,
            _,
        };
    };
};
