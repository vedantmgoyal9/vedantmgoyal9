import { useEffect, useState } from 'react';
import CodeBlock from '@theme/CodeBlock';

export default () => {
  const [result, setOutput] = useState<string>(
    'Please enter required inputs...',
  );
  const [pkgId, setPkgId] = useState<string>('');
  const [instRegex, setInstRegex] = useState<string>(
    '.(exe|msi|msix|appx)(bundle){0,1}$',
  );
  const [releaseTag, setReleaseTag] = useState<string>('');
  const [ghToken, setGhToken] = useState<string>('');
  const [ghRepo, setGhRepo] = useState<string>('');
  useEffect(() => {
    if (pkgId === '') return setOutput('Please enter a package identifier.');
    if (ghRepo === '')
      return setOutput(
        'Please enter the GitHub repo on which you plan to implement the action.',
      );
    const reqHeaders = { Accept: 'application/vnd.github.v3+json' };
    if (ghToken !== '') reqHeaders['Authorization'] = `token ${ghToken}`;
    fetch(
      `https://api.github.com/repos/${ghRepo}/releases/${
        releaseTag ? `tag/${releaseTag}` : 'latest'
      }`,
      { headers: reqHeaders },
    ).then((res) => {
      if (!res.ok)
        return setOutput(
          `Can't fetch release. Please check the inputs and try again.
Status code: ${res.status} ${
            res.status === 403
              ? '(Looks like GitHub API rate-limit exceeded)'
              : ''
          }
Url: ${res.url}`,
        );
      res.json().then((data) => {
        setOutput(
          JSON.stringify(
            {
              PackageIdentifier: pkgId,
              PackageVersion: /(?<=v).*/g.exec(data.tag_name)[0],
              InstallerUrls: data.assets.flatMap((element) =>
                new RegExp(instRegex, 'g').test(element.name)
                  ? element.browser_download_url
                  : [],
              ),
            },
            null,
            2,
          ),
        );
      });
    });
  }, [pkgId, instRegex, releaseTag, ghToken, ghRepo]);
  return (
    <div>
      <label htmlFor="pkg-id" className="input">
        <input
          type="text"
          id="pkg-id"
          name="pkg-id"
          className="input-field"
          placeholder="Identifier of the package in winget-pkgs (case-sensitive)"
          onChange={(event) => setPkgId(event.target.value)}
        />
        <span className="input-label">Identifier</span>
      </label>

      <label htmlFor="pkg-version" className="input">
        <input
          type="text"
          id="pkg-version"
          name="pkg-version"
          className="input-field"
          value="The PackageVersion of package, would be used as it is, if provided. See: https://github.com/vedantmgoyal2009/winget-releaser/#readme"
          disabled
        />
        <span className="input-label">Version</span>
      </label>

      <label htmlFor="inst-regex" className="input">
        <input
          type="text"
          id="inst-regex"
          name="inst-regex"
          className="input-field"
          placeholder="Regular expression to filter installer URLs"
          defaultValue=".(exe|msi|msix|appx)(bundle){0,1}$"
          onChange={(event) => setInstRegex(event.target.value)}
        />
        <span className="input-label">Installers Regex</span>
      </label>

      <label htmlFor="max-versions-to-keep" className="input">
        <input
          type="text"
          id="max-versions-to-keep"
          name="max-versions-to-keep"
          className="input-field"
          value="⚠️ Not available on web version :-("
          disabled
        />
        <span className="input-label">Max versions to keep</span>
      </label>

      <label htmlFor="release-tagname" className="input">
        <input
          type="text"
          id="release-tagname"
          name="release-tagname"
          className="input-field"
          placeholder="This playground will use latest release, if not provided."
          onChange={(event) => setReleaseTag(event.target.value)}
        />
        <span className="input-label">Release Tag</span>
      </label>

      <label htmlFor="auth-tkn" className="input">
        <input
          type="text"
          id="auth-tkn"
          name="auth-tkn"
          className="input-field"
          placeholder="You can give a GitHub token, as unauthenticated GitHub API requests are rate-limited (60 requests/hour)"
          onChange={(event) => setGhToken(event.target.value)}
        />
        <span className="input-label">
          Token (optional for playground only)
        </span>
      </label>

      <label htmlFor="user-forked" className="input">
        <input
          type="text"
          id="user-forked"
          name="user-forked"
          className="input-field"
          value="⚠️ Not available on web version :-("
          disabled
        />
        <span className="input-label">Fork user</span>
      </label>

      <hr />

      <label htmlFor="test-repo" className="input">
        <input
          type="text"
          id="test-repo"
          name="test-repo"
          className="input-field"
          placeholder="Repository on which action will be tested"
          onChange={(event) => setGhRepo(event.target.value)}
        />
        <span className="input-label">GitHub Repository (owner/repo)</span>
      </label>

      <CodeBlock title="Playground Output">{result}</CodeBlock>
    </div>
  );
};
