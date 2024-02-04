import { useEffect, useState } from 'react';
import Markdown from 'react-markdown';
import rehypeRaw from 'rehype-raw';
import rehypeSanitize from 'rehype-sanitize';
import remarkGfm from 'remark-gfm';

export default ({ src }) => {
  const [content, setContent] = useState<string>('');

  useEffect(() => {
    (async () => {
      const response = await fetch(src);
      const text = await response.text();
      setContent(text);
    })();
  }, []);

  return (
    <Markdown
      remarkPlugins={[remarkGfm]}
      rehypePlugins={[rehypeRaw, rehypeSanitize]}>
      {content}
    </Markdown>
  );
};
