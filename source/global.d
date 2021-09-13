// Copyright (c) 2021 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// Recompresses directories of files to 7z
// https://github.com/workhorsy/smol

import std.stdint;

public import dlib.core.memory : New, Delete;

alias int8_t    s8;
alias int16_t   s16;
alias int32_t   s32;
alias int64_t   s64;

alias uint8_t   u8;
alias uint16_t  u16;
alias uint32_t  u32;
alias uint64_t  u64;

int _fps = 0;
shared string g_root_path = null;
shared bool g_is_running = false;
