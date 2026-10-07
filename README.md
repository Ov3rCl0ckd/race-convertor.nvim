# race-convertor.nvim 🏎️

> **Work in Progress (WIP)**

A Neovim plugin designed for students and developers who prefer coding in Neovim but need to submit or compile standard Visual Studio Solutions (`.sln`). 

With a single command, this plugin takes your `.c`, `.cpp`, `.h`, and `.hpp` files and automatically generates a perfect, highly-structured Visual Studio Enterprise (v145) Solution folder—complete with `Source Files` and `Header Files` Solution Explorer filters, and explicitly configured as a Console Application so it pauses correctly (`Ctrl+F5`). It even synchronously compiles it in the background using MSBuild to ensure your executable is ready instantly.

## 📦 Installation

Install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    "Ov3rCl0ckd/race-convertor.nvim",
    cmd = "ExportToVS",
    keys = {
        { "<leader>ll", "<cmd>ExportToVS<cr>", desc = "Export to Visual Studio" },
    },
    config = function()
        require("race_convertor").setup({})
    end
}
```

## 🚀 Usage

1. Open Neovim in a directory containing your C/C++ source code.
2. Press `<leader>ll` or type `:ExportToVS`.
3. A floating window will prompt you for a Project Name.
4. Type your desired name and press `Enter`.
5. The plugin will freeze Neovim for a few seconds while it perfectly structures your XML files and compiles the binary via MSBuild in the background.
6. Check your workspace! A new directory named `YourProjectName_VS_Export` will be sitting there containing your pristine `.sln` file and your compiled executable.

## 🛠️ Features
- Generates 100% native `.vcxproj` and `.sln` XML formats.
- Automatically handles `.vcxproj.filters` so your files appear neatly in Visual Studio's "Header Files" and "Source Files" folders.
- Automatically injects `<SubSystem>Console</SubSystem>` so your program waits for user input when run via `Ctrl+F5` in VS.
- Automatically compiles the project synchronously using `vswhere.exe` and `MSBuild.exe`.
- Ignores build artifacts (`build/`, `out/`, `.vs/`) so you get a clean export every time.

## 🚧 Status
This project is currently a **Work in Progress**. Expect frequent updates and refactors as the XML string generators are optimized and improved.
