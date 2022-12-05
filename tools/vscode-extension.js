// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const { fstat } = require('fs');
const vscode = require('vscode');

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
  // Use the console to output diagnostic information (console.log) and errors (console.error)
  // This line of code will only be executed once when your extension is activated
  console.log(
    'Congratulations, your extension "vedantmgoyal2009" is now active!',
  );

  // The command has been defined in the package.json file
  // Now provide the implementation of the command with  registerCommand
  // The commandId parameter must match the command field in package.json
  let disposable = vscode.commands.registerCommand(
    'vedantmgoyal2009.helloWorld',
    function () {
      // The code you place here will be executed every time your command is executed

      // Display a message box to the user
      vscode.window.showInformationMessage(
        'Hello World from vedantmgoyal2009 extension!',
      );
    },
  );

  let testWpaPkgs = vscode.commands.registerCommand(
    'vedantmgoyal2009.testWpaPackageJson',
    async () => {
      let pkgList = new Map();
      let dirContents = await vscode.workspace.findFiles(
        `winget-pkgs-automation/packages/**/*.json`,
      );
      if (dirContents.length === 0) {
        vscode.window.showInformationMessage(
          'No packages found. Please verify you have opened vedantmgoyal2009 folder in your workspace.',
        );
        return;
      }
      dirContents.forEach((file) => {
        let packageIdentifier = file.path.substring(
          file.path.lastIndexOf('/') + 1,
          file.path.lastIndexOf('.'),
        );
        pkgList.set(packageIdentifier, file.fsPath);
      });
      vscode.window
        .showQuickPick(Array.from(pkgList.keys()).sort(), {
          title: 'Select a package',
          placeHolder: 'Select a package from the list',
          canPickMany: false,
        })
        .then((selectedPackageId) => {
          vscode.window
            .createTerminal({
              name: `Test ${selectedPackageId}`,
              cwd: `${vscode.workspace.workspaceFolders[0].uri.fsPath}/tools`,
              shellPath: 'pwsh',
              shellArgs: [
                '-NoExit',
                '-NoProfile',
                '-Command',
                './Manage-WpaPackages.ps1',
                '-PackageIdentifier',
                `${selectedPackageId}`,
                '-TestPackage',
              ],
              hideFromUser: false,
            })
            .show();
        });
    },
  );

  context.subscriptions.push(disposable);
  context.subscriptions.push(testWpaPkgs);
}

// this method is called when your extension is deactivated
function deactivate() {}

module.exports = {
  activate,
  deactivate,
};
