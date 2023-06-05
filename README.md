# Resource Leak Checker (RLC#) for C# code using CodeQL

RLC# is a light-weight and modular resource leak checker for C# code. It is inspired by [Checker Framework's](https://checkerframework.org/) resource leak checker (RLC) for Java.
RLC# is developed as a CodeQL query.

## Prerequisites

This setup currently works only for Windows machine

- Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).
- Install [CodeQL CLI](https://docs.github.com/en/code-security/codeql-cli/using-the-codeql-cli/getting-started-with-the-codeql-cli#checking-out-the-codeql-source-code-directly).

## How to use?

First download the CodeQL databases from LGTM and extract the database folders from the compressed files. You can also [create a CodeQL database](https://docs.github.com/en/code-security/codeql-cli/using-the-codeql-cli/creating-codeql-databases).

Update the `HOME` variable in `run-all-services.sh` to provide path to the CodeQL repository that is cloned when you install CodeQL CLI.

To run RLC# on a list of CodeQL databases, run the following script with a list of paths to the CodeQL database folders.
```bash
./scripts/run-all-services.sh <list-of-codeql-databases>
```

For each database, a sub-directory is created inside results/rlc-warnings that contains a file named `f-rlc-i-all.csv`. The resource leak warnings generated by RLC# are listed in this file.
Each row in the file `f-rlc-i-all.csv` corresponds to a potential resource leak. The second column in a row gives the name of the source file in which the resource leak is detected and the third column gives the start line number. The first column provides meta information (type of resource, `L` stands for library type and `C` stands for custom type) for the resource leak warning.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
