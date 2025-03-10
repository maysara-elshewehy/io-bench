// Copyright (c) 2025 SuperZIG All rights reserved.
//
// repo: https://github.com/Super-ZIG/io
//
// Made with ❤️ by Maysara
//
// maysara.elshewehy@gmail.com.
// https://github.com/maysara-elshewehy



// ╔══════════════════════════════════════ ---- ══════════════════════════════════════╗

    const std                   = @import("std");
    const unicode               = @import("../unicode/unicode.zig");
    pub const Allocator         = std.mem.Allocator;
    pub const RangeError        = error { OutOfRange };
    pub const CapacityError     = error { OutOfMemory };
    pub const PositionError     = error { InvalidPosition };

// ╚══════════════════════════════════════════════════════════════════════════════════╝



// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    // Todo: refactor this module.
    // The new version of the `string module` uses a different API, so integration is needed.

    // ┌─────────────────────── Initialization ───────────────────────┐

        pub const initError = RangeError;

        /// Initializes an array of chars of a given `size`, filled with null chars.
        pub inline fn initWithCapacity(comptime T: type, comptime initial_size: usize) [initial_size]T {
            return .{0} ** initial_size;
        }

        /// Initializes an array of chars of a given `size` and `value`,
        /// terminated with a null char **if the `array_size` is greater than the length of `value`**.
        /// - `error.OutOfRange` **_if the length of `value` exceeds `size`._**
        pub inline fn initWithSlice(comptime T: type, comptime initial_size: usize, initial_value: []const T) initError![initial_size]T {
            if(initial_value.len > initial_size) return initError.OutOfRange;
            if(initial_size == 0 or initial_value.len == 0) return initWithCapacity(T, initial_size);

            return initWithSliceAssumeCapacity(T, initial_size, initial_value);
        }

        /// Initializes an array of chars of a given `size` and `value`,
        pub inline fn initWithSliceAssumeCapacity(comptime T: type, comptime initial_size: usize, initial_value: []const T) [initial_size]T {
            var result: [initial_size]T = undefined;
            @memcpy(result[0..initial_value.len], initial_value[0..initial_value.len]);
            if(initial_value.len < initial_size) result[initial_value.len] = 0;
            return result;
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌─────────────────────────── Insert ───────────────────────────┐

        pub const InsertError = RangeError || CapacityError;

        /// Inserts a `slice` into `dest` at the specified `position` by **real position**.
        /// - `error.OutOfRange` **_if the insertion exceeds the bounds of `dest`._**
        /// - `error.OutOfRange` **_if the `pos` is greater than `written_len`._**
        pub inline fn insertSlice(comptime T: type, dest: []T, slice: []const T, written_len: usize, pos: usize) InsertError!void {

            if (slice.len == 0) return;
            if (pos > written_len) return InsertError.OutOfRange;
            if (written_len+slice.len > dest.len) return InsertError.OutOfMemory;

            insertSliceAssumeCapacity(T, dest, slice, written_len, pos);
        }

        /// -
        pub inline fn insertSliceAssumeCapacity(comptime T: type, dest: []T, slice: []const T, written_len: usize, pos: usize) void {
            const shiftLen = slice.len;
            std.mem.copyBackwards(T, dest[pos + shiftLen..], dest[pos..written_len]);
            @memcpy(dest[pos..pos + shiftLen], slice);
        }

        /// Inserts a `char` into `dest` at the specified `position` by **real position**.
        /// - `error.OutOfRange` **_if the insertion exceeds the bounds of `dest`._**
        /// - `error.OutOfRange` **_if the `pos` is greater than `written_len`._**
        pub inline fn insertChar(comptime T: type, dest: []T, char: T, written_len: usize, pos: usize) InsertError!void {
            if (pos > written_len) return InsertError.OutOfRange;
            if (written_len+1 > dest.len) return InsertError.OutOfMemory;

            insertCharAssumeCapacity(T, dest, char, written_len, pos);
        }

        /// -
        pub inline fn insertCharAssumeCapacity(comptime T: type, dest: []T, char: T, written_len: usize, pos: usize) void {
            std.mem.copyBackwards(T, dest[pos+1..], dest[pos..written_len]);
            dest[pos] = char;
        }

        /// Inserts a `slice` into `dest` at the specified `visual position`.
        /// - `error.OutOfMemory` **_if the insertion exceeds the bounds of `dest`._**
        /// - `error.OutOfRange` **_if the `pos` is invalid or greater than `written_len`._**
        pub inline fn visualInsertSlice(comptime T: type, dest: []T, slice: []const T, written_len: usize, pos: usize) InsertError!void {
            if(T != u8) @compileError("visualInsertSlice is only available for u8 (i will improve it in the future)");

            const real_pos = unicode.getRealPosition(dest[0..written_len], pos) catch return InsertError.OutOfRange;
            return insertSlice(T, dest, slice, written_len, real_pos);
        }

        /// Inserts a `char` into `dest` at the specified `visual position`.
        /// - `error.OutOfMemory` **_if the insertion exceeds the bounds of `dest`._**
        /// - `error.OutOfRange` **_if the `pos` is invalid or greater than `written_len`._**
        pub inline fn visualInsertChar(comptime T: type, dest: []T, char: T, written_len: usize, pos: usize) InsertError!void {
            if(T != u8) @compileError("visualInsertChar is only available for u8 (i will improve it in the future)");

            const real_pos = unicode.getRealPosition(dest[0..written_len], pos) catch return InsertError.OutOfRange;
            return insertChar(T, dest, char, written_len, real_pos);
        }

        /// Appends a `slice` into `dest`.
        /// - `error.OutOfMemory` **_if the insertion exceeds the bounds of `dest`._**
        pub inline fn appendSlice(comptime T: type, dest: []T, slice: []const T, written_len: usize) InsertError!void {
            if (slice.len == 0) return;
            if (written_len+slice.len > dest.len) return InsertError.OutOfMemory;

            appendSliceAssumeCapacity(T, dest, slice, written_len);
        }

        /// -
        pub inline fn appendSliceAssumeCapacity(comptime T: type, dest: []T, slice: []const T, written_len: usize) void {
            const old_len = written_len;
            const new_len = old_len + slice.len;
            std.debug.assert(new_len <= dest.len);
            @memcpy(dest[old_len..new_len], slice);
        }

        /// Appends a `char` into `dest`.
        /// - `error.OutOfMemory` **_if the insertion exceeds the bounds of `dest`._**
        pub inline fn appendChar(comptime T: type, dest: []T, char: T, written_len: usize) InsertError!void {
            if (written_len+1 > dest.len) return InsertError.OutOfMemory;

            appendCharAssumeCapacity(T, dest, char, written_len);
        }

        /// -
        pub inline fn appendCharAssumeCapacity(comptime T: type, dest: []T, char: T, written_len: usize) void {
            dest[written_len] = char;
        }

        /// Prepends a `slice` into `dest`.
        /// - `error.OutOfMemory` **_if the insertion exceeds the bounds of `dest`._**
        pub inline fn prependSlice(comptime T: type, dest: []T, slice: []const T, written_len: usize) InsertError!void {
            try insertSlice(T, dest, slice, written_len, 0);
        }

        /// -
        pub inline fn prependAssumeCapacity(comptime T: type, dest: []T, slice: []const T, written_len: usize) void {
            insertSliceAssumeCapacity(T, dest, slice, written_len, 0);
        }

        /// Prepends a `char` into `dest`.
        /// - `error.OutOfMemory` **_if the insertion exceeds the bounds of `dest`._**
        pub inline fn prependChar(comptime T: type, dest: []T, char: T, written_len: usize) InsertError!void {
            try insertChar(T, dest, char, written_len, 0);
        }

        /// -
        pub inline fn prependCharAssumeCapacity(comptime T: type, dest: []T, char: T, written_len: usize) void {
            insertCharAssumeCapacity(T, dest, char, written_len, 0);
        }

        /// -
        pub inline fn addManyAtAssumeCapacity(comptime T: type, dest: []T, written_len: usize, index: usize, count: usize) []T {
            const new_len = written_len + count;
            std.debug.assert(dest.len >= new_len);
            const to_move = dest[index..];
            std.mem.copyBackwards(T, dest[index + count ..], to_move);
            const result = dest[index..][0..count];
            @memset(result, undefined);
            return result;
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌─────────────────────────── Remove ───────────────────────────┐

        pub const removeIndexError = RangeError;
        pub const removeVisualIndexError = removeIndexError || PositionError;

        /// Removes a char from the `dest`.
        /// - `removeIndexError.OutOfRange` **_if the `pos` is greater than `written_len`._**
        pub inline fn removeIndex(comptime T: type, dest: []T, written_len: usize, pos: usize) removeIndexError!void {
            if (pos > written_len) return removeIndexError.OutOfRange;
            return removeUnchecked(T, dest, written_len, pos);
        }
        pub inline fn removeUnchecked(comptime T: type, dest: []T, written_len: usize, pos: usize) void {
            std.mem.copyForwards(T, dest[pos..], dest[pos+1..written_len]);
        }

        /// Removes a char from the `dest` by the `visual position`.
        /// - `error.InvalidPosition` **_if the `pos` is invalid._**
        /// - `error.OutOfRange` **_if the `pos` is greater than `written_len`._**
        ///
        /// Returns the removed slice.
        pub inline fn removeVisualIndex(comptime T: type, dest: []T, written_len: usize, pos: usize) removeVisualIndexError![]const T {
            if(T != u8) @compileError("removeVisualIndex is only available for u8 (i will improve it in the future)");

            if (pos > written_len) return removeVisualIndexError.OutOfRange;
            const real_pos = unicode.getRealPosition(dest[0..written_len], pos) catch return removeVisualIndexError.InvalidPosition;
            if(unicode.getFirstGraphemeClusterSlice(dest[real_pos..written_len])) |gc| {
                removeRangeUnchecked(T, dest, written_len, real_pos, gc.len);
                return gc;
            }

            return removeVisualIndexError.InvalidPosition;
        }

        /// Removes a `range` of chars from the `dest`.
        /// - `removeIndexError.InvalidPosition` **_if the `pos` is invalid._**
        /// - `removeIndexError.OutOfRange` **_if the `pos` is greater than `written_len`._**
        pub inline fn removeRange(comptime T: type, dest: []T, written_len: usize, pos: usize, len: usize) removeIndexError!void {
            if (pos+len > written_len) return removeIndexError.OutOfRange;
            return removeRangeUnchecked(T, dest, written_len, pos, len);
        }

        /// -
        pub inline fn removeRangeUnchecked(comptime T: type, dest: []T, written_len: usize, pos: usize, len: usize) void {
            std.mem.copyForwards(T, dest[pos..], dest[pos+len..written_len]);
        }

        /// Removes a `range` of chars from the `dest` by the `visual position`.
        /// - `error.InvalidPosition` **_if the `pos` is invalid._**
        /// - `error.OutOfRange` **_if the `pos` is greater than `written_len`._**
        ///
        /// Returns the removed slice.
        pub inline fn removeVisualRange(comptime T: type, dest: []T, written_len: usize, pos: usize, len: usize) removeVisualIndexError![]const T {
            if(T != u8) @compileError("removeVisualRange is only available for u8 (i will improve it in the future)");

            if (pos+len > written_len) return removeVisualIndexError.OutOfRange;
            const real_pos = unicode.getRealPosition(dest[0..written_len], pos) catch return removeVisualIndexError.InvalidPosition;

            var real_len : usize = 0;
            var unicode_iterator = unicode.Iterator.init(dest[real_pos..written_len]) catch return removeVisualIndexError.InvalidPosition;
            for(0..len) |_| {
                if(unicode_iterator.nextGraphemeClusterSlice()) |gc| real_len += gc.len
                else return removeVisualIndexError.InvalidPosition;
            }

            if(unicode.getFirstGraphemeClusterSlice(dest[real_pos..written_len])) |gc| {
                removeRangeUnchecked(T, dest, written_len, real_pos, real_len);
                return gc;
            }

            return removeVisualIndexError.InvalidPosition;
        }

        // The behavior of this `pop` function is different
        // from its counterparts in this library.
        // Here we are dealing directly with the array,
        // not with a data type dedicated to containing the array,
        // so it should be left as is or considered an internal function only.
        //
        /// Returns the length of the last grapheme cluster at the `dest`.
        pub inline fn pop(comptime T: type, dest: []const T) usize {
            const len = (unicode.getLastGraphemeClusterSlice(dest[0..]) orelse return 0).len;
            return len;
        }

        /// Removes the first grapheme cluster at the `dest`,
        /// Returns the number of removed chars.
        pub inline fn shift(comptime T: type, dest: []T) usize {
            const len = (unicode.getFirstGraphemeClusterSlice(dest[0..]) orelse return 0).len;
            std.mem.copyForwards(T, dest[0..], dest[len..]);
            return len;
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Find ────────────────────────────┐

        /// Finds the `position` of the **first** occurrence of `target`.
        pub inline fn find(comptime T: type, dest: []const T, target: []const T) ?usize {
            return std.mem.indexOf(T, dest, target);
        }

        /// Finds the `visual position` of the **first** occurrence of `target`.
        pub inline fn findVisual(comptime T: type, dest: []const T, target: []const T) ?usize {
            if(T != u8) @compileError("findVisual is only available for u8 (i will improve it in the future)");

            if(find(T, dest, target)) |pos| return unicode.getVisualPosition(dest, pos) catch null;
            return null;
        }

        /// Finds the `position` of the **last** occurrence of `target`.
        pub inline fn findLast(comptime T: type, dest: []const T, target: []const T) ?usize {
            return std.mem.lastIndexOf(T, dest, target);
        }

        /// Finds the `visual position` of the **last** occurrence of `target`.
        pub inline fn findLastVisual(comptime T: type, dest: []const T, target: []const T) ?usize {
            if(T != u8) @compileError("findVisual is only available for u8 (i will improve it in the future)");

            if(findLast(T, dest, target)) |pos| return unicode.getVisualPosition(dest, pos) catch null;
            return null;
        }

        /// Returns `true` **if `dest` contains `target`**.
        pub inline fn includes(comptime T: type, dest: []const T, target: []const T) bool {
            if(find(T, dest, target)) |_| return true;
            return false;
        }

        /// Returns `true` **if `dest` starts with `target`**.
        pub inline fn startsWith(comptime T: type, dest: []const T, target: []const T) bool {
            return std.mem.startsWith(T, dest, target);
        }

        /// Returns `true` **if `dest` ends with `target`**.
        pub inline fn endsWith(comptime T: type, dest: []const T, target: []const T) bool {
            return std.mem.endsWith(T, dest, target);
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Case ────────────────────────────┐

        /// Converts all (ASCII) letters to lowercase.
        pub inline fn toLower(comptime T: type, value: []T) void {
            var i: usize = 0;
            while (i < value.len) {
                const first_char_size = unicode.getLengthOfStartByte(value[i]) catch 1;
                if (first_char_size == 1) value[i] = std.ascii.toLower(value[i]);
                i += first_char_size;
            }
        }

        /// Converts all (ASCII) letters to uppercase.
        pub inline fn toUpper(comptime T: type, value: []T) void {
            var i: usize = 0;
            while (i < value.len) {
                const first_char_size = unicode.getLengthOfStartByte(value[i]) catch 1;
                if (first_char_size == 1) value[i] = std.ascii.toUpper(value[i]);
                i += first_char_size;
            }
        }

        // Converts all (ASCII) letters to titlecase.
        pub inline fn toTitle(comptime T: type, value: []T) void {
            if (value.len == 0) return;

            var i: usize = 0;
            var is_new_word: bool = true;

            while (i < value.len) {
                const char = value[i];

                if (std.ascii.isWhitespace(char)) {
                    is_new_word = true;
                    i += 1;
                    continue;
                }

                if (is_new_word) {
                    value[i] = std.ascii.toUpper(char);
                    is_new_word = false;
                } else value[i] = std.ascii.toLower(char);

                i += 1;
            }
        }

        /// Reverses the order of the chars.
        pub inline fn reverse(comptime T: type, value: []T) void {
            std.mem.reverse(T, value);
        }

        /// Reverses the order of the chars in the `slice` (considering Unicode).
        pub inline fn reverseUnicode(comptime T: type, dist: []T, dist_wlen: usize, temp: []const T) void {
            var unicode_iterator = unicode.Iterator.initUnchecked(temp[0..]);
            var i: usize = dist_wlen;

            while (unicode_iterator.nextGraphemeClusterSlice()) |gc| {
                i -= gc.len;
                @memcpy(dist[i..i + gc.len], gc);
                if (i == 0) break; // to avoid underflow.
            }
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Check ───────────────────────────┐

        /// Returns `true` **if the value is a valid char**.
        pub inline fn isChar(comptime T: type, value: anytype) bool {
            const value_type = @TypeOf(value);
            return value_type == T
                or (value_type == comptime_int and value >= 0 and value <= 255);
        }

        /// Returns `true` **if the value is a valid array of chars**.
        pub inline fn isSlice(comptime T: type, value: anytype) bool {
            const value_type = @TypeOf(value);

            // Direct match for known char types
            if (value_type == []T or value_type == []const T) return true;

            const type_info = @typeInfo(value_type);

            // Check if it's a pointer to an array of chars
            if (type_info == .pointer) {
                const child_type_info = @typeInfo(type_info.pointer.child);
                if (child_type_info == .array) return child_type_info.array.child == T;
            }

            // Check if it's a direct array of chars
            if (type_info == .array) return type_info.array.child == T;

            return false;
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Count ───────────────────────────┐

        pub const countVisualError = error { InvalidValue };


        /// Returns the total number of written chars, stopping at the first null char.
        pub inline fn countWritten(comptime T: type, value: []const T) usize {
            for(0..value.len) |i| if(value[i] == 0) return i;
            return value.len;
        }

        /// Returns the total number of visual chars.
        /// - `countVisualError.InvalidValue` **_if the `value` is not a valid unicode format._**
        pub inline fn countVisual(comptime T: type, value: []const T) countVisualError!usize {
            if(T != u8) @compileError("countVisual is only available for u8 (i will improve it in the future)");

            const len = countWritten(u8, value);
            var count : usize = 0;
            var i : usize = 0;
            while (i < len) {
                i += (unicode.getFirstGraphemeClusterSlice(value[i..len]) orelse return countVisualError.InvalidValue).len;
                count += 1;
            }
            return count;
        }

        /// Returns a slice containing only the written part.
        pub inline fn writtenSlice(comptime T: type, value: []const T) []const T {
            return value[0..countWritten(u8, value)];
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Split ───────────────────────────┐

        /// Splits the written portion of the string into substrings separated by the delimiter,
        /// returning the substring at the specified index.
        pub inline fn split(comptime T: type, dest: []const T, written_len: usize, delimiters: []const T, index: usize) ?[]const T {
            var current_index: usize = 0;
            var start: usize = 0;
            var i: usize = 0;

            while (i < written_len) {
                const slice = dest[i..written_len];
                if (unicode.getFirstGraphemeClusterSlice(slice)) |gc| {
                    const gc_len = gc.len;
                    const gc_chars = dest[i..@min(i + gc_len, written_len)];

                    // Check for delimiter match
                    if (gc_len == delimiters.len and i + gc_len <= written_len and std.mem.eql(T, delimiters, gc_chars)) {
                        if (current_index == index) return dest[start..i];
                        current_index += 1;
                        start = i + gc_len;
                        i = start;
                    } else i += gc_len;
                } else {
                    // Handle invalid unicode
                    if (delimiters.len == 1 and i < written_len and dest[i] == delimiters[0]) {
                        if (current_index == index) return dest[start..i];
                        current_index += 1;
                        start = i + 1;
                        i = start;
                    } else i += 1;
                }
            }

            // Handle final segment
            if (current_index == index and start <= written_len) return dest[start..written_len];

            return null;
        }

        /// Splits the written portion of the string into all substrings separated by the delimiter,
        /// returning an array of slices. Caller must free the returned memory.
        /// `include_empty` controls whether empty strings are included in the result.
        pub inline fn splitAll(comptime T: type, allocator: Allocator, dest: []const T, written_len: usize, delimiters: []const T, include_empty: bool) Allocator.Error![]const []const T {
            var parts = std.ArrayList([]const T).init(allocator);
            errdefer parts.deinit();

            var i: usize = 0;
            while (split(T, dest, written_len, delimiters, i)) |slice| : (i += 1) {
                // Include empty strings based on the flag
                if (include_empty or slice.len > 0) try parts.append(slice);
            }

            // Handle case where no splits occurred but content exists
            if (parts.items.len == 0 and written_len > 0) try parts.append(dest[0..written_len]);

            return parts.toOwnedSlice();
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌─────────────────────────── Replace ──────────────────────────┐

        pub const replaceError = error{ OutOfRange };

        /// Replaces all occurrence of a character with another.
        pub inline fn replaceAllChars(comptime T: type, dest: []T, match: T, replacement: T) void {
            std.mem.replaceScalar(T, dest, match, replacement);
        }

        /// Replaces all occurrences of a slice with another.
        pub inline fn replaceAllSlices(comptime T: type, dest: [] T, written_len: usize, match: []const T, replacement: []const T) replaceError!usize {
            var res : usize = 0;
            while(find(T, dest[0..written_len], match)) |find_res| {
                try replaceRange(T, dest, written_len, find_res, match.len, replacement);
                res += 1;
            }

            return res;
        }

        /// Replaces a range of chars with another.
        pub inline fn replaceRange(comptime T: type, dest: []T, written_len: usize, start: usize, len: usize, replacement: []const T) replaceError!void {
            const after_range = start + len;
            const range = dest[start..after_range];
            if (range.len < replacement.len) {
                const first = replacement[0..range.len];
                const rest = replacement[range.len..];
                @memcpy(range[0..first.len], first);
                insertSlice(T, dest, rest, written_len, after_range) catch return replaceError.OutOfRange;
            } else {
                replaceRangeAssumeCapacity(T, dest, written_len, start, len, replacement);
            }
        }

        pub inline fn replaceRangeAssumeCapacity(comptime T: type, dest: []T, written_len: usize, start: usize, len: usize, replacement: []const T) void {
            const after_range = start + len;
            const range = dest[start..after_range];

            if (range.len == replacement.len)
                @memcpy(range[0..replacement.len], replacement)
            else if (range.len < replacement.len) {
                const first = replacement[0..range.len];
                const rest = replacement[range.len..];
                @memcpy(range[0..first.len], first);
                const dst = addManyAtAssumeCapacity(T, dest, written_len, after_range, rest.len);
                @memcpy(dst, rest);
            } else {
                const extra = range.len - replacement.len;
                @memcpy(range[0..replacement.len], replacement);
                std.mem.copyForwards( T, dest[after_range - extra ..], dest[after_range..], );
                @memset(dest[written_len - extra ..], undefined);
            }
        }

        /// Replaces a visual range of chars with another.
        pub inline fn replaceVisualRange(comptime T: type, dest: []T, written_len: usize, start: usize, len: usize, replacement: []const T) replaceError!void {
            if(T != u8) @compileError("replaceVisualRange is only available for u8 (i will improve it in the future)");

            var new_len : usize = 0;
            var iter = unicode.Iterator.init(dest[start..written_len]) catch unreachable;
            var i : usize = 0;

            while(iter.nextGraphemeClusterSlice()) |gc| {
                new_len += gc.len;
                i += 1;
                if(i == len) break;
            }

            try replaceRange(T, dest, written_len, start, new_len, replacement);
        }

    // └──────────────────────────────────────────────────────────────┘


    // ┌──────────────────────────── Utils ───────────────────────────┐

        /// Returns true if the `a` is equal to `b`.
        pub inline fn equals(comptime T: type, a: []const T, b: []const T) bool {
            if(a.len != b.len) return false;
            if(a.len == 0) return true;

            return std.mem.eql(T, a, b);
        }

        /// Returns true if the `value` is empty.
        pub inline fn isEmpty(comptime T: type, value: []const T) bool {
            return countWritten(u8, value) == 0;
        }

        /// Prints the contents of the `slice` instance to the given writer.
        pub inline fn printTo(slice: []const u8, _writer: anytype) !void {
            if(slice.len > 0)
            try _writer.writeAll(slice[0..]);
        }

        /// Prints the contents of the `slice` to the standard writer.
        pub inline fn print(slice: []const u8) !void {
            if(slice.len > 0)
            try std.io.getStdOut().writer().writeAll(slice[0..]);
        }

        /// Prints the contents of the `slice` to the standard writer and adds a newline.
        pub inline fn printWithNewLine(slice: []const u8) !void {
            if(slice.len > 0) {
                try std.io.getStdOut().writer().writeAll(slice[0..]);
                try std.io.getStdOut().writer().writeByte('\n');
            }
        }

    // └──────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════╝