Package.describe({
  name: 'video-analysis',
  version: "1.0.0"
});

Package.onUse(function (api) {
  // api.export('SimpleChat');
  api.use(['mongo', 'accounts-base', 'iron:router', 'less']);
  api.use(['templating', 'jquery', 'reactive-var', 'blaze-html-templates', 'session'], ['client']);

  // lib
  api.addFiles([
    'lib/collections.js'
  ], ['client','server']);

  api.addAssets([
    'images/homeai.png'
  ], 'client');

  api.addFiles([
    'client/index.html',
    'client/index.js',
    'client/index.less',

    // templates
    'client/template/search.html',
    'client/template/history.html',
    'client/template/history.js',
    'client/template/detail.html',
    'client/template/detail.js',
  ], 'client');
});