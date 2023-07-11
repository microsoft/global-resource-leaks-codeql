# Resource Leak Checker (RLC#) for C# code using CodeQL

RLC# is a light-weight and modular resource leak checker for C# code. It is inspired by [Checker Framework's](https://checkerframework.org/) resource leak checker (RLC) for Java.
RLC# is developed as a CodeQL query.

## Prerequisites


- Install [dotnet](https://dotnet.microsoft.com/en-us/download).
- Install [CodeQL CLI](https://docs.github.com/en/code-security/codeql-cli/using-the-codeql-cli/getting-started-with-the-codeql-cli#checking-out-the-codeql-source-code-directly).
- Install python3.

## How to use?

First download the CodeQL databases from LGTM and extract the database folders from the compressed files. You can also [create a CodeQL database](https://docs.github.com/en/code-security/codeql-cli/using-the-codeql-cli/creating-codeql-databases).

To run RLC# on a list of CodeQL databases, run the following command and give a CodeQL database as an argument on which you want to run RLC#. This command first runs inference query to infer resource management specifications which are used by RLC#.
```python3
python3 scripts/inference.py <codeql-db> && python3 scripts/rlc.py <codeql-db>
```

The script `rlc.py` creates a file `csharp-results/<name-of-codeql-db>-rlc-warnings-with-inferred-annotations.csv` that contains a list of resource leak warnings. Each row in the file corresponds to a potential resource leak. It contains meta information and the location where the resource was allocated, which may not be disposed along some path.

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
