// Copyright (c) 2025 SuperZIG All rights reserved.
//
// repo: https://github.com/Super-ZIG/io
//
// Made with ❤️ by Maysara
//
// maysara.elshewehy@gmail.com.
// https://github.com/maysara-elshewehy



// ╔══════════════════════════════════════ ---- ══════════════════════════════════════╗

    const std = @import("std");

// ╚══════════════════════════════════════════════════════════════════════════════════╝



// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    // ┌────────────────────────── Codepoint ─────────────────────────┐

        /// A struct to represent a single Unicode codepoint with properties.
        pub const Codepoint = struct {

            // ┌──────────────────────────── ---- ────────────────────────────┐

                const Self = @This();

                /// Unified error set of `Codepoint` functions.
                pub const Error = error { InvalidValue };

                /// Modes of the codepoint.
                pub const Mode = enum { ZWJ, Mod, None };

            // └──────────────────────────────────────────────────────────────┘


            // ┌─────────────────────────── Fields ───────────────────────────┐

                /// The mode of the code point _(`ZeroWidthJointer`/`Modifier`/`None`)_.
                mode: Mode,

                /// The length of the codepoint slice.
                len: usize,

            // └──────────────────────────────────────────────────────────────┘


            // ┌────────────────────────── Methods ───────────────────────────┐

                /// Initializes a `Codepoint` instance with the specified slice.
                /// - `Error.InvalidValue` **_if the `slice` is not a valid unicode._**
                pub fn init(slice: []const u8) Error!Self {
                    if(slice.len == 0) return Error.InvalidValue;
                    if(!Utf8Validate(slice)) return Error.InvalidValue;

                    const decoded_value = Utf8Decode(slice) catch return Error.InvalidValue;
                    return .{
                        .mode = if(decoded_value == 0x200d) .ZWJ else if(isModifier(decoded_value)) .Mod else .None,
                        .len = slice.len,
                    };
                }

                /// Returns `true` if the code point is a modifier using **_the decoded code point value._**
                inline fn isModifier(codepoint: u21) bool {
                    return switch (codepoint) {
                        0x0300...0x036F,  // Combining Diacritical Marks
                        0x1AB0...0x1AFF,  // Combining Diacritical Marks Extended
                        0x1DC0...0x1DFF,  // Combining Diacritical Marks Supplement
                        0x20D0...0x20FF,  // Combining Diacritical Marks for Symbols
                        0xFE20...0xFE2F,  // Combining Half Marks
                        0xFE00...0xFE0F   // Variation Selectors
                        => true,
                        else => false,
                    };
                }

            // └──────────────────────────────────────────────────────────────┘
        };

    // └──────────────────────────────────────────────────────────────┘


    // ┌────────────────────────── Iterator ──────────────────────────┐

        /// A _(`grapheme cluster`, `codepoint`)_ iterator for iterating over a slice of chars.
        pub const Iterator = struct {

            // ┌──────────────────────────── ---- ────────────────────────────┐

                const Self = @This();

                /// Unified error set of `iterator` functions.
                pub const Error = error { InvalidValue };

                /// Modes of the iterator.
                pub const modes = enum { codepoint, graphemeCluster };

            // └──────────────────────────────────────────────────────────────┘


            // ┌─────────────────────────── Fields ───────────────────────────┐

                /// The input slice to iterate over.
                src: []const u8,

                /// The current position of the iterator.
                pos: usize,

            // └──────────────────────────────────────────────────────────────┘


            // ┌────────────────────────── Methods ───────────────────────────┐

                /// Initializes an `Iterator` with the given input slice.
                /// Returns `Error.InvalidValue` **_if the `initial_slice` is not a valid unicode._**
                pub fn init(initial_slice: []const u8) Error!Self {
                    if(!Utf8Validate(initial_slice)) return Error.InvalidValue;
                    return initUnchecked(initial_slice);
                }

                /// Initializes an `Iterator` with the given input slice without validation.
                pub inline fn initUnchecked(initial_slice: []const u8) Self {
                    return .{ .src = initial_slice, .pos = 0, };
                }

                /// Returns the next codepoint slice and advances the iterator.
                pub inline fn nextCodepointSlice(self: *Self) ?[]const u8 {
                    return self.getNextSlice(.codepoint);
                }

                /// Returns the next grapheme cluster slice and advances the iterator.
                pub inline fn nextGraphemeClusterSlice(self: *Self) ?[]const u8 {
                    return self.getNextSlice(.graphemeCluster);
                }

                /// Decodes and returns the next codepoint and advances the iterator.
                pub inline fn next(self: *Self) ?u21 {
                    const slice = self.nextCodepointSlice() orelse return null;
                    return Utf8Decode(slice[0..]) catch null;
                }

                /// Decodes and returns the next codepoint without advancing the iterator.
                pub inline fn peek(self: *Self, codepoints_count: usize) ?[]const u8 {
                    const original_i = self.pos;
                    defer self.pos = original_i;

                    var end_ix = original_i;
                    var found: usize = 0;
                    while (found < codepoints_count) : (found += 1) {
                        const next_codepoint_slice = self.nextCodepointSlice() orelse return null;
                        end_ix += next_codepoint_slice.len;
                    }

                    return self.src[original_i..end_ix];
                }

                /// Returns the next slice depending on the mode and advances the iterator.
                inline fn getNextSlice(self: *Self, mode: modes) ?[]const u8 {
                    if (self.pos >= self.src.len) return null;
                    const cp_len = switch (mode) {
                        .codepoint => getLengthOfStartByte(self.src[self.pos]) catch return null,
                        .graphemeCluster => (getFirstGraphemeClusterSlice(self.src[self.pos..]) orelse return null).len,
                    };

                    self.pos += cp_len;
                    return self.src[self.pos - cp_len..self.pos];
                }

            // └──────────────────────────────────────────────────────────────┘
        };

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Utils ───────────────────────────┐

        pub const getRealPositionError   = error { InvalidValue, OutOfRange };
        pub const getVisualPositionError = getRealPositionError;


        /// Returns length of the codepoint depending on the first byte.
        /// - `error.InvalidValue` **_if the `byte` is not valid a utf8 start char._**
        pub inline fn getLengthOfStartByte(byte: u8) error{InvalidValue}!usize {
            return switch (byte) {
                0b0000_0000...0b0111_1111 => 1,
                0b1100_0000...0b1101_1111 => 2,
                0b1110_0000...0b1110_1111 => 3,
                0b1111_0000...0b1111_0111 => 4,
                else => error.InvalidValue,
            };
        }

        /// Returns the first codepoint slice.
        pub inline fn getFirstCodepointSlice(value: []const u8) ?[]const u8 {
            if(!Utf8Validate(value)) return null;
            if(value.len == 0) return null;
            return value[0..getLengthOfStartByte(value[0]) catch null];
        }

        /// Returns the first codepoint.
        pub inline fn getFirstCodepoint(value: []const u8) ?Codepoint {
            return Codepoint.init((getFirstCodepointSlice(value) orelse return null)) catch null;
        }

        /// Returns the last codepoint slice.
        pub inline fn getLastCodepointSlice(value: []const u8) ?[]const u8 {
            if(value.len == 0) return null;
            var i : usize = value.len;
            while(i > 0) {
                const char = value[i - 1];
                // check if the char is part of the unicode sequence
                // and try to get the index of the start char of this codepoint.
                if ((char & 0xC0) != 0x80) return value[i-1 ..];
                i -= 1;
            }
            return null;
        }

        /// Returns the last codepoint.
        pub inline fn getLastCodepoint(value: []const u8) ?Codepoint {
            return Codepoint.init((getLastCodepointSlice(value) orelse return null)) catch null;
        }

        /// Returns the first grapheme cluster slice.
        pub inline fn getFirstGraphemeClusterSlice(value: []const u8) ?[]const u8 {
            if(!Utf8Validate(value)) return null;
            if(value.len == 0) return null;

            var iterator = std.unicode.Utf8Iterator{ .bytes = value, .i = 0 };
            var previous_codepoint :? Codepoint = null;
            var counted_length : usize = 0;

            while(iterator.nextCodepointSlice()) |curr_cp| {
                const current_codepoint = Codepoint.init(curr_cp) catch return null;

                // Check previous codepoint.
                if(previous_codepoint) |prev_cp| {
                    if(prev_cp.mode == .ZWJ or (prev_cp.mode == .None and current_codepoint.mode == .Mod)) {
                        counted_length += current_codepoint.len;
                        previous_codepoint = current_codepoint;
                        continue;
                    } else break;
                }

                // First Time.
                else counted_length += current_codepoint.len;

                // Check next codepoint.
                const original_i = iterator.i;
                if(iterator.nextCodepointSlice()) |next_cp| {
                    const next_codepoint = Codepoint.init(next_cp) catch return null;

                    if(next_codepoint.mode == .ZWJ) {
                        previous_codepoint = next_codepoint;
                        counted_length += next_codepoint.len;
                        continue;
                    }
                }

                // Reset the current iterator index if the next codepoint is not a jointer.
                iterator.i = original_i;

                // Update the previous codepoint to the current one.
                previous_codepoint = current_codepoint;
            }

            return value[0..counted_length];
        }

        /// Returns the last grapheme cluster slice.
        pub inline fn getLastGraphemeClusterSlice(value: []const u8) ?[]const u8 {
            // TODO: clean this up.

            if(!Utf8Validate(value)) return null;
            if(value.len == 0) return null;

            // Use getLastCodepoint to quickly find the last codepoint in the string
            var last_end_i : usize = value.len;
            var last_beg_i : usize = value.len;
            var current_i : usize = value.len;
            var next_of_current_cp_was_None : bool = true;

            // Iterate through the codepoint sequence backwards
            while (true) {
                // Use getLastCodepoint to quickly find the last codepoint in the string
                const current_cp = getLastCodepoint(value[0..current_i]) orelse return null;

                if(current_cp.len == 1) return value[last_beg_i-1..last_end_i];

                last_beg_i -= current_cp.len;
                current_i = last_beg_i;

                if(next_of_current_cp_was_None){
                    last_end_i = current_i+current_cp.len;
                }

                // is the current is Modifier or ZWJ ? skip
                if(current_cp.mode == .Mod or current_cp.mode == .ZWJ) {
                    next_of_current_cp_was_None = false;
                    continue;
                }

                if(current_i == 0) {
                    return value[last_beg_i..last_end_i];
                } else {
                    while(true) {
                        const prev_cp = getLastCodepoint(value[0..last_beg_i]) orelse return value[last_beg_i..last_end_i];

                        last_beg_i -= prev_cp.len;
                        current_i = last_beg_i;

                        if(prev_cp.mode == .ZWJ) continue;

                        if(!next_of_current_cp_was_None or prev_cp.len == 1) return value[last_beg_i+prev_cp.len..last_end_i];

                        return value[last_beg_i..last_end_i];
                    }
                }

                next_of_current_cp_was_None = true;
            }
        }

        /// Returns the real position in the array based on the visual position.
        /// - `getRealPositionError.OutOfRange` **_if `visual_pos` is out of range._**
        /// - `getRealPositionError.InvalidValue` **_if `value` is not valid unicode._**
        pub inline fn getRealPosition(value: []const u8, visual_pos: usize) getRealPositionError!usize {
            if(visual_pos > value.len) return getRealPositionError.OutOfRange;

            var i: usize = 0;
            var j: usize = 0;

            while (i < value.len and value[i] != 0 and j < visual_pos) {
                i += (getFirstGraphemeClusterSlice(value[i..]) orelse return getRealPositionError.InvalidValue).len;
                j += 1;
            }

            return i;
        }

        /// Returns the visual position in the array based on the real position.
        /// - `getVisualPositionError.OutOfRange` **_if `real_pos` is out of range._**
        /// - `getVisualPositionError.InvalidValue` **_if `value` is not valid unicode._**
        pub inline fn getVisualPosition(value: []const u8, real_pos: usize) getVisualPositionError!usize {
            if (real_pos > value.len) return getVisualPositionError.OutOfRange;

            var i: usize = 0;
            var j: usize = 0;

            while (i < value.len and value[i] != 0 and i < real_pos) {
                i += (getFirstGraphemeClusterSlice(value[i..]) orelse return getRealPositionError.InvalidValue).len;
                j += 1;
            }

            return j;
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌────────────────────────── Shortcuts ─────────────────────────┐

        /// Returns true if the input consists entirely of UTF-8 codepoints.
        pub const Utf8Validate = std.unicode.utf8ValidateSlice;

        /// Decodes a UTF-8 codepoint slice into a codepoint value.
        pub const Utf8Decode   = std.unicode.utf8Decode;

    // └──────────────────────────────────────────────────────────────┘


// ╚══════════════════════════════════════════════════════════════════════════════════╝