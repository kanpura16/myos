const trb = @import("trb.zig");
const console = @import("../../../console.zig");

pub var cmd_ring: Ring = Ring{};
// pub var transfer_ring: Ring align(64) = Ring{};

const Ring = struct {
    trb: [64]u128 align(64) = undefined,
    enqueue_ptr: usize = 0,
    cycle_bit: u1 = 1,

    pub fn push(self: *@This(), elem_trb: *u128) void {
        self.trb[self.enqueue_ptr] = blk: {
            const tmp_trb: *trb.Trb = @ptrCast(elem_trb);
            tmp_trb.field.cycle_bit = self.cycle_bit;
            break :blk tmp_trb.value;
        };

        self.enqueue_ptr += 1;
        if (self.enqueue_ptr == self.trb.len - 1) {
            self.trb[self.enqueue_ptr] = blk: {
                var link_trb = trb.LinkTrb{ .field = .{} };
                link_trb.field.ring_segment_ptr = @intCast(@intFromPtr(&self.trb[0]) >> 4);
                link_trb.field.cycle_bit = self.cycle_bit;
                link_trb.field.toggle_cycle = 1;
                break :blk link_trb.value;
            };

            self.enqueue_ptr = 0;
            self.cycle_bit = ~self.cycle_bit;
        }
    }
};
