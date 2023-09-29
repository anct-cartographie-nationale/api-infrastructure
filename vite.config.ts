import * as path from 'path';
import { defineConfig } from 'vite';

const inputFor = (folders: string[]) =>
  folders.reduce(
    (
      inputs: { [key: string]: string },
      folder: string,
    ): { [key: string]: string } => ({
      ...inputs,
      [`${folder}/index`]: path.resolve(__dirname, `src/${folder}/index.ts`),
    }),
    {},
  );

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
        ...inputFor(['api-keys-authorizer', 'import-from-s3']),
      },
      output: {
        entryFileNames: '[name].mjs',
      },
    },
  },
});
