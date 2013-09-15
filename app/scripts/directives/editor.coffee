
angular.module('cortadoApp')


.directive 'aceEditor', () ->
  restrict: 'A'
  require: '?ngModel'
  scope: false
  link: (scope, elm, attrs, ngModel) ->
    scope.acee = acee = window.ace.edit(elm[0])
    scope.session = session = acee.getSession()
    scope.mode = attrs.mode


    acee.setTheme("ace/theme/solarized_light")
    acee.getSession().setMode("ace/mode/#{scope.mode}")
    acee.setOption 'useWrapMode', true
    acee.setOption 'showGutter', true
    acee.setReadOnly false
    acee.setHighlightActiveLine false

    if angular.isDefined(ngModel)
      ngModel.$formatters.push (value) ->
        if angular.isUndefined(value) or value is null
          return ''
        else if angular.isObject(value) or angular.isArray(value)
          throw new Error('ace-editor cannot use an object or an array as a model')
        return value
      ngModel.$render = -> session.setValue(ngModel.$viewValue)

    session.on 'change', (e) ->
      newValue = session.getValue()
      if newValue isnt scope.$eval(attrs.value) and !scope.$$phase and angular.isDefined(ngModel)
        scope.$apply -> ngModel.$setViewValue(newValue)

  controller: ($scope, $rootScope) ->
    $rootScope.$on 'panel_resized', ()-> $scope.acee.resize()

    $scope.themes = [
      'merbivore', 'merbivore_soft', 'mono_industrial', 'monokai', 'pastel_on_dark', 'solarized_dark',
      'solarized_light', 'terminal', 'textmate', 'tomorrow', 'tomorrow_night', 'tomorrow_night_blue',
      'tomorrow_night_eighties', 'twilight', 'vibrant_ink', 'xcode'
    ]

    $scope.setTheme = (name) ->
      $scope.acee.setTheme "ace/theme/" + name
