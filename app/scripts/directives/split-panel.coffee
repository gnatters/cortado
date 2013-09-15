angular.module('cortadoApp')

.directive 'splitRow', () ->
  restrict: 'E'
  transclude: true
  scope: {}
  replace: true
  template: '<div class="split-row" ng-transclude></div>'
  controller: ($scope, $element, $compile, $rootScope) ->
    $scope.row = $element[0]
    cols = $scope.$parent.cols = []

    $scope.$parent.col = (name) ->
      (c for c in cols when c.name is name)[0]

    body = document.getElementsByTagName("body")[0]
    body.addEventListener 'click', () ->
      $rootScope.$broadcast 'bg_click'
    $(document).keyup (e) ->
      $rootScope.$broadcast 'bg_click' if e.keyCode is 27 # esc

    this.equalCols = (ncols) ->
      ncols ||= (c for c in cols when c.show).length
      new_ratio = 1/ncols
      for c in cols
        if c.show
          c.ratio = new_ratio
        else
          c.ratio = 0

    this.findLastCol = () ->
      return unless cols.length
      last_shown = null
      for c in cols
        c.last_shown = false
        last_shown = c if c.show
      last_shown.last_shown = true if last_shown


    this.addCol = (col) ->
      $scope.$apply () =>
        col.index = cols.length
        cols.push col
        this.equalCols()
        col.div.append $compile('<drag-area ng-show="!last_shown"></drag-area>')(col)

    window.r = $scope.row

    dragged = (x) =>
      $scope.$apply () =>
        before = $scope.dragging
        after = cols[i = before.index+1]
        after = cols[++i] until after.show # could inifinite loop, but should never
        cumRatio = (c.ratio for c in cols when c.index < before.index).reduce(((t, s) -> t + s), 0)
        before.ratio = (x-$scope.row.offsetLeft) / this.row_width - cumRatio

        if before.ratio < 0.1
          before.ratio = 0.1
        after.ratio = 1 - (cols[i].ratio for i of cols when parseInt(i) isnt after.index).reduce(((t, s) -> t + s), 0)
        if after.ratio < 0.1
          after.ratio = 0.1
          before.ratio = 1 - (cols[i].ratio for i of cols when parseInt(i) isnt before.index).reduce(((t, s) -> t + s), 0)

        before.div[0].onresize() if before.div[0].onresize
        after.div[0].onresize() if after.div[0].onresize
        $rootScope.$broadcast 'panel_resized'

    ($scope.row.onresize = () => this.row_width = $scope.row.offsetWidth)()

    this.start_drag = (col, e) ->
      _.kill_event(e)
      $scope.dragging = col

    document.onmousemove = (e) ->
      _.kill_event(e)
      dragged(e.clientX) if $scope.dragging
      # trigger mousemoved broadcast unless a resizablePanel has already caught and handled this event
      unless e.caughtBy
        $rootScope.$broadcast 'mousemoved'

    document.onmouseup = () -> $scope.dragging = null


.directive 'resizablePanel', ($rootScope) ->
  require: '^splitRow'
  restrict: 'E'
  transclude: true
  scope:
    name: '@'
    show: '@'
  replace: true
  template: '<div class="resizable-panel" ng-transclude ng-style="{width: \'\'+(ratio*100)+\'%\'}" ng-show="show"></div>'
  controller: ($scope, $rootScope) ->
    $scope.$watch 'show', () ->
      $scope.show = !!$scope.show
      $scope.ctrl.equalCols()
      $scope.ctrl.findLastCol()
      setTimeout -> $rootScope.$broadcast 'panel_resized'
  link: (scope, elm, attrs, splitRowCtrl) ->
    scope.div = elm
    scope.ctrl = splitRowCtrl
    scope.mouseover = false
    setTimeout (() -> scope.show = !!scope.show; splitRowCtrl.addCol(scope)), 0

    elm.bind 'mousemove', (e) ->
      e.originalEvent.caughtBy = scope.name
      unless scope.mouseover
        $rootScope.$broadcast 'mousemoved', scope.name
    scope.$on 'mousemoved', (e, name) ->
      scope.$apply -> scope.mouseover = name is scope.name



.directive 'dragArea', () ->
  restrict: 'E'
  replace: true
  template: '<div class="drag-area"></div>'
  scope: false
  link: (scope, elm, attrs) ->
    elm.bind 'mousedown', (e) -> scope.ctrl.start_drag(scope, e)

