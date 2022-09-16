import React, { useEffect, useState } from 'react';
import CodeBlock from '@theme/CodeBlock';

export default function WrPlayground() {
  const [result, setOutput] = useState('Please enter the required inputs...');
  const [pkgId, setPkgId] = useState('');
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
          setOutput(
            JSON.stringify(
              {
                PackageIdentifier: pkgId,
                PackageVersion: /(?<=v).*/g.exec(data.tag_name)[0],
                InstallerUrls: data.assets.flatMap((element) =>
                  new RegExp(instRegex, 'g').test(element.name)
                    ? element.browser_download_url
                    : []
                ),
                ReleaseDate: new Date(data.published_at).toISOString().slice(0, 10),
                ReleaseNotesUrl: data.html_url,
              },
              null,
              2
            )
          );
        });
      }
    );
  }, [pkgId, instRegex, ghRepo]);
  return (
    <div>
      <label htmlFor="pkg-id" className="input">
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

      <label htmlFor="pkg-version" className="input">
        <input
          type="text"
          id="pkg-version"
          name="pkg-version"
          className="input-field"
          value="The PackageVersion of package, would be used as it is, if provided. See: https://github.com/vedantmgoyal2009/winget-releaser/#version-version"
          disabled="true"
        />
        <span className="input-label"> Version </span>
      </label>

      <label htmlFor="inst-regex" className="input">
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

      <label htmlFor="release-tagname" className="input">
        <input
          type="text"
          id="release-tagname"
          name="release-tagname"
          className="input-field"
          value="⚠️ Not available on web version :-("
          disabled="true"
        />
        <span className="input-label"> Release Tag </span>
      </label>

      <label htmlFor="del-prev-ver" className="input">
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

      <label htmlFor="auth-tkn" className="input">
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

      <label htmlFor="user-forked" className="input">
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

      <label htmlFor="test-repo" className="input">
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
