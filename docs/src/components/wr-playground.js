import React, { useEffect, useState } from 'react';
import CodeBlock from '@theme/CodeBlock';

export default function WrPlayground() {
  const [result, setOutput] = useState('Please enter the required inputs...');
  const [pkgId, setPkgId] = useState('');
  const [verRegex, setVerRegex] = useState('[0-9.]+');
  const [instRegex, setInstRegex] = useState(
    '.(exe|msi|msix|appx)(bundle){0,1}$'
  );
  const [ghRepo, setGhRepo] = useState('');
  useEffect(() => {
    if (pkgId === '') {
      setOutput('Please enter a package identifier');
      return;
    }
    if (ghRepo === '') {
      setOutput(
        "Please enter the GitHub repository on which you're planning to implement the action"
      );
      return;
    }
    fetch('https://api.github.com/repos/' + ghRepo + '/releases/latest').then(
      (res) => {
        res.json().then((data) => {
          setOutput(`Package Identifier: ${pkgId}\n` +
          `Package Version: ${new RegExp(verRegex, 'g').exec(data.tag_name)}\n` +
          `Installer Urls: ${JSON.stringify(
            data.assets.flatMap((element) =>
              new RegExp(instRegex, 'g').test(element.name)
                ? element.browser_download_url
                : []
            ), null, 2
          )}
          `);
        });
      }
    );
  }, [pkgId, verRegex, instRegex, ghRepo]);
  return (
    <div>
      <label for="pkg-id" className="input">
        <input
          type="text"
          id="pkg-id"
          name="pkg-id"
          className="input-field"
          placeholder="Identifier of the package in winget-pkgs"
          onChange={(event) => {
            setPkgId(event.target.value);
          }}
        />
        <span className="input-label"> Identifier </span>
      </label>

      <label for="ver-regex" className="input">
        <input
          type="text"
          id="ver-regex"
          name="ver-regex"
          className="input-field"
          placeholder="RegEx to select version from GitHub release tag"
          defaultValue="[0-9.]+"
          onChange={(event) => {
            setVerRegex(event.target.value);
          }}
        />
        <span className="input-label"> Version Regex </span>
      </label>

      <label for="inst-regex" className="input">
        <input
          type="text"
          id="inst-regex"
          name="inst-regex"
          className="input-field"
          placeholder="Regular expression to filter installer URLs"
          defaultValue=".(exe|msi|msix|appx)(bundle){0,1}$"
          onChange={(event) => {
            setInstRegex(event.target.value);
          }}
        />
        <span className="input-label"> Installer Regex </span>
      </label>

      <label for="del-prev-ver" className="input">
        <input
          type="text"
          id="del-prev-ver"
          name="del-prev-ver"
          className="input-field"
          value="⚠️ Not available on web version :-("
          disabled="true"
        />
        <span className="input-label"> Delete Previous Version </span>
      </label>

      <label for="auth-tkn" className="input">
        <input
          type="text"
          id="auth-tkn"
          name="auth-tkn"
          className="input-field"
          value="⚠️ Not available on web version :-("
          disabled="true"
        />
        <span className="input-label"> Token </span>
      </label>

      <label for="user-forked" className="input">
        <input
          type="text"
          id="user-forked"
          name="user-forked"
          className="input-field"
          value="⚠️ Not available on web version :-("
          disabled="true"
        />
        <span className="input-label"> Fork user </span>
      </label>

      <hr />

      <label for="test-repo" className="input">
        <input
          type="text"
          id="test-repo"
          name="test-repo"
          className="input-field"
          placeholder="Repository on which action will be tested"
          onChange={(event) => {
            setGhRepo(event.target.value);
          }}
        />
        <span className="input-label"> GitHub Repository (owner/repo)</span>
      </label>

      <CodeBlock title="Playground Output">{result}</CodeBlock>
    </div>
  );
}
