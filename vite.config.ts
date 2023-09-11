import * as path from 'path';
import { defineConfig } from 'vite';

const inputFor = (folder: string) => ({
  [`${folder}/index`]: path.resolve(__dirname, `src/${folder}/index.ts`),
});

export default defineConfig({
  build: {
    outDir: '',
    lib: {
      entry: '',
      formats: ['es'],
    },
    rollupOptions: {
      external: /^@aws-sdk/,
      input: {
        ...inputFor('import-from-s3'),
      },
      output: {
        entryFileNames: '[name].mjs',
      },
    },
  },
});
