angular.module('cortadoApp')

.directive 'renderPanel', ($compile) ->
  restrict: 'A'
  replace: true
  template: '<div class="render-panel"></div>'
  scope: true
  link: (scope, elm, attrs) ->
    scope.$watch attrs.renderPanel, (md) ->
      raw_html = if md and md.replace(/\s*/,'') then markdown.toHTML(md) else ''
      elm.html $compile(raw_html)(scope)
      prettyPrint()


.directive 'prettyPrintPanel', ($filter) ->
  restrict: 'A'
  replace: true
  template: '<div class="pp-panel"></div>'
  scope: true
  link: (scope, elm, attrs) ->
    scope.$watch attrs.prettyPrintPanel, (code) ->
      raw_html = if code and code.replace(/\s*/,'') then markdown.toHTML(code) else ''
      pre = angular.element('<pre class="prettyprint lang-html"></pre>')
      code = angular.element('<code></code>')
      code.html $filter('escapeHTML')(raw_html)
      pre.append code
      elm.html pre
      prettyPrint()
  controller: ($scope, $http) ->
    $scope.$parent.theme = theme =
      list: ['google-code-light','solarized-dark','solarized-light','sons-of-obsidian-dark',
      'tomorrow-night-blue','tomorrow-night-dark','tomorrow-night-light','tomorrow-night-eighties']
      selected: 'google-code-light'

    $scope.$watch 'theme.selected', (theme_name) ->
      url = "styles/gprettify/#{theme_name}.css"
      $http.get(url).then (response) ->
        theme.css = response.data

