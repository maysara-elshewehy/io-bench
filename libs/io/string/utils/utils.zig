// Copyright (c) 2025 SuperZIG All rights reserved.
//
// repo: https://github.com/Super-ZIG/io
// docs: https://super-zig.github.io/io/string/
//
// Made with ❤️ by Maysara
//
// maysara.elshewehy@gmail.com.
// https://github.com/maysara-elshewehy



// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    /// A set of useful functions for working with bytes.
    pub const bytes = @import("./bytes/bytes.zig");

    /// A set of useful functions for working with unicode.
    pub const unicode = @import("./unicode/unicode.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════╝



// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    test {
        _ = @import("./bytes/test.zig");
        _ = @import("./unicode/test.zig");
    }

// ╚══════════════════════════════════════════════════════════════════════════════════╝