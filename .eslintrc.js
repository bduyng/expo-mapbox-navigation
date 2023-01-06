module.exports = {
  root: true,
  extends: ['universe/native', 'universe/web'],
  'prettier/prettier': ['error', { singleQuote: true }],
  ignorePatterns: ['build'],
};
