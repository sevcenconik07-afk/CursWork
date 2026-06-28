# USM Latex Template

This repository contains an opinionated Latex template configured according to USM standards.

# Usage

## Cloning the Repository

Use `git` to get a local copy of this repository.
Install `git` if you don't have it yet.

```shell
cd ~
git clone https://github.com/AntonC9018/uni_thesisTemplate
cd uni_thesisTemplate
```

> Note that it is very important to have the project be a git repository!
> Some features may not work otherwise.

## Installation

### Windows

> [There's a video in russian.](https://youtu.be/UCardvw13-s)

For Windows users, it is highly recommended to use WSL.
For installation instructions, see [this](https://learn.microsoft.com/en-us/windows/wsl/install).

Once you got WSL, refer to the [Ubuntu](#Ubuntu) section for further instructions.

Now, the template may work on Windows without WSL.
The reason it's not recommended is because Latex is known
to cause issues on Windows because of incorrect package versions.
Latex on Linux is more stable in this regard.

### Ubuntu

Run `source ./setup.sh`. It is going to:
- Install a minimal Latex distro globally;
- Install the required packages;
- Add the Times New Roman font;
- Add the Latex directory to `PATH` and to `.bashrc`.

> Modify the setup script and rerun it if you need more Latex packages.
> It's not going to reinstall the Latex distro if it's already installed.

## Compiling the Thesis

1. **Choose Your Language:** Rename the main `.tex` file 
   corresponding to your language (`ru`/`ro`).

   ```shell
   cp thesis/bare_main_ro.tex thesis/main.tex
   ```

2. **Choose the document type and specialty:** In `main.tex`, the template import must include one language and one document type:

   ```tex
   \usepackage[romanian,master]{config}
   \specialty{informatica_aplicata}
   ```

   For Russian and practice reports, use the same pattern:

   ```tex
   \usepackage[russian,master_practica_2]{config}
   \specialty{informatica_aplicata}
   ```

   Supported document types are `master`, `an`, `licenta`, `licenta_practica_1`, `licenta_practica_2`, `licenta_practica_3`, `master_practica_2`, and `custom`.

3. **Compile the PDF:**

   ```shell
   cd thesis
   ./render.sh
   ```

### VS Code

This repository includes a VS Code launch configuration. Open any `.tex`
file inside `thesis/` and press `F5` to render it with `thesis/render.sh`
and open the generated PDF in your browser automatically.
This also works when VS Code is opened on Windows through a WSL path.

The same command is available as the default build task, so `Ctrl+Shift+B`
also renders the currently open `.tex` file.

VS Code is also configured to hide repository internals and generated Latex
files from the Explorer, while keeping generated PDFs visible.

## But I don't know Latex...

Here's an overview of the process:
- There's the **source file**, which is the `main.tex` file;
- There's the **Latex compiler**, which *compiles* it to make a PDF;
- The PDF is output in the same directory as the `main.tex` file, you can view it normally in the browser.

I suggest you look through `main.tex` and correlate 
this source file with what you see in the PDF.
Play around with it, see how changes in the source file affect the PDF, 
see what errors the compiler gives.
You will be able to learn most of what you need to write your work like this.

## Notes on prompting LLMs

I know most of you won't even bother looking through the examples in the file
and will go straight into copy-pasting AI generated text into your document.
If you do, at least add the example file into the context 
by copy-pasting it into the prompt alongside yours.
This will significantly improve the chances of your document compiling properly.

## The compile script doesn't work after changes

In this case, you should clear the latex cache.
To recompile having cleared the cache, run `./render.sh -f`.

> Note that clearing the cache relies on `git`, 
> so you **must have your project be a git repository.**
