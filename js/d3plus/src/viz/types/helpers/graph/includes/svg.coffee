mix         = require "../../../../../color/mix.coffee"
textwrap    = require "../../../../../textwrap/textwrap.coffee"
validObject = require "../../../../../object/validate.coffee"

module.exports = (vars) ->

  domains = vars.x.domain.viz.concat vars.y.domain.viz
  return null if domains.indexOf(undefined) >= 0

  bgStyle =
    width:  vars.axes.width
    height: vars.axes.height
    fill:   vars.axes.background.color
    stroke:            vars.axes.background.stroke.color
    "stroke-width":    vars.axes.background.stroke.width
    "shape-rendering": vars.axes.background.rendering.value

  alignMap =
    left:   "start"
    center: "middle"
    right:  "end"

  axisData = if vars.small then [] else [0]

  tickPosition = (tick, axis) ->
    tick
      .attr "x1", (d) ->
        if axis is "x" then vars.x.scale.viz(d) else 0
      .attr "x2", (d) ->
        if axis is "x" then vars.x.scale.viz(d) else vars.axes.width
      .attr "y1", (d) ->
        if axis is "y" then vars.y.scale.viz(d) else 0
      .attr "y2", (d) ->
        if axis is "y" then vars.y.scale.viz(d) else vars.axes.height

  tickStyle = (tick, axis, grid) ->

    color = if grid then vars[axis].grid.color else vars[axis].ticks.color
    log   = vars[axis].scale.value is "log"

    tick
      .attr "stroke", (d) ->

        return vars[axis].axis.color if d is 0

        d = +d if d.constructor is Date
        visible = vars[axis].ticks.visible.indexOf(d) >= 0

        if visible and (!log or Math.abs(d).toString().charAt(0) is "1")
          color
        else if grid
          mix(color, vars.axes.background.color, 0.4, 1)
        else
          mix(color, vars.background.value, 0.4, 1)

      .attr "stroke-width"   , vars[axis].ticks.width
      .attr "shape-rendering", vars[axis].ticks.rendering.value

  getFontStyle = (axis, val, style) ->
    type = if val is 0 then "axis" else "ticks"
    val = vars[axis][type].font[style]
    if val and (val.length or typeof val is "number") then val else vars[axis].ticks.font[style]

  tickFont = (tick, axis) ->
    log = vars[axis].scale.value is "log"
    tick
      .attr "font-size"  , (d) -> getFontStyle(axis, d, "size") + "px"
      .attr "fill"       , (d) ->
        color = getFontStyle(axis, d, "color")
        if !log or Math.abs(d).toString().charAt(0) is "1"
          color
        else
          mix(color, vars.background.value, 0.4, 1)
      .attr "font-family", (d) -> getFontStyle(axis, d, "family").value
      .attr "font-weight", (d) -> getFontStyle(axis, d, "weight")

  lineStyle = (line, axis) ->

    max = if axis is "x" then "height" else "width"
    opp = if axis is "x" then "y" else "x"

    line
      .attr opp+"1", 0
      .attr opp+"2", vars.axes[max]
      .attr axis+"1", (d) -> d.coords.line
      .attr axis+"2", (d) -> d.coords.line
      .attr "stroke"          , (d) -> d.color or vars[axis].lines.color
      .attr "stroke-width"    , vars[axis].lines.width
      .attr "shape-rendering" , vars[axis].lines.rendering.value
      .attr "stroke-dasharray", vars[axis].lines.dasharray.value

  lineFont = (text, axis) ->

    opp = if axis is "x" then "y" else "x"

    text
      .attr opp          , (d) -> d.coords.text[opp] + "px"
      .attr axis         , (d) -> d.coords.text[axis]+"px"
      .attr "dy"         , vars[axis].lines.font.position.value
      .attr "text-anchor", alignMap[vars[axis].lines.font.align.value]
      .attr "transform"  , (d) -> d.transform
      .attr "font-size"  , vars[axis].lines.font.size+"px"
      .attr "fill"       , (d) -> d.color or vars[axis].lines.color
      .attr "font-family", vars[axis].lines.font.family.value
      .attr "font-weight", vars[axis].lines.font.weight

  # Draw Plane Group
  planeTrans = "translate(" + vars.axes.margin.left + "," + vars.axes.margin.top + ")"
  plane = vars.group.selectAll("g#d3plus_graph_plane").data [0]
  plane.transition().duration vars.draw.timing
    .attr "transform", planeTrans
  plane.enter().append "g"
    .attr "id", "d3plus_graph_plane"
    .attr "transform", planeTrans

  # Draw Background Rectangle
  bg = plane.selectAll("rect#d3plus_graph_background").data [0]
  bg.transition().duration vars.draw.timing
    .attr bgStyle
  bg.enter().append "rect"
    .attr "id", "d3plus_graph_background"
    .attr "x", 0
    .attr "y", 0
    .attr bgStyle

  # Draw Triangular Axes Mirror
  mirror = plane.selectAll("path#d3plus_graph_mirror").data [0]
  mirror.enter().append "path"
    .attr "id", "d3plus_graph_mirror"
    .attr "fill", "#000"
    .attr "fill-opacity", 0.03
    .attr "stroke-width", 1
    .attr "stroke", "#ccc"
    .attr "stroke-dasharray", "10,10"
    .attr "opacity", 0
  mirror.transition().duration vars.draw.timing
    .attr "opacity", () -> if vars.axes.mirror.value then 1 else 0
    .attr "d", () ->
      w = bgStyle.width
      h = bgStyle.height
      "M "+w+" "+h+" L 0 "+h+" L "+w+" 0 Z"

  # Draw X Axis Tick Marks
  rotated = vars.x.ticks.rotate isnt 0
  xStyle  = (axis) ->

    groups = axis
      .attr "transform", "translate(0," + vars.axes.height + ")"
      .call vars.x.axis.svg.scale(vars.x.scale.viz)
      .selectAll("g.tick")

    groups.selectAll("line")
      .attr "y2", (d) ->
        d  = +d if d.constructor is Date
        y2 = d3.select(this).attr("y2")
        if vars.x.ticks.visible.indexOf(d) >= 0 then y2 else y2/2

    groups.select("text")
        .attr "dy", ""
        .style "text-anchor", if rotated then "end" else "middle"
        .call tickFont, "x"
        .each "end", (d) ->
          d = +d if d.constructor is Date
          if !vars.x.ticks.hidden and vars.x.ticks.visible.indexOf(d) >= 0
            textwrap()
              .container(d3.select(this))
              .rotate(vars.x.ticks.rotate)
              .valign(if rotated then "middle" else "top")
              .width(vars.x.ticks.maxWidth)
              .height(vars.x.ticks.maxHeight)
              .padding(0)
              .x(-vars.x.ticks.maxWidth/2)
              .draw()

  xAxis = plane.selectAll("g#d3plus_graph_xticks").data axisData
  xAxis.transition().duration vars.draw.timing
    .call xStyle
  xAxis.selectAll("line").transition().duration vars.draw.timing
    .call tickStyle, "x"
  xEnter = xAxis.enter().append "g"
    .attr "id", "d3plus_graph_xticks"
    .transition().duration 0
    .call xStyle
  xEnter.selectAll("path").attr "fill", "none"
  xEnter.selectAll("line").call tickStyle, "x"
  xAxis.exit().transition().duration vars.data.timing
    .attr "opacity", 0
    .remove()

  # Draw Y Axis Tick Marks
  yStyle = (axis) ->

    groups = axis
      .call vars.y.axis.svg.scale(vars.y.scale.viz)
      .selectAll("g.tick")

    groups.selectAll("line")
      .attr "y2", (d) ->
        d  = +d if d.constructor is Date
        y2 = d3.select(this).attr("y2")
        if vars.x.ticks.visible.indexOf(d) >= 0 then y2 else y2/2

    groups.select("text")
      .call tickFont, "y"

  yAxis = plane.selectAll("g#d3plus_graph_yticks").data axisData
  yAxis.transition().duration(vars.draw.timing).call yStyle
  yAxis.selectAll("line").transition().duration vars.draw.timing
    .call tickStyle, "y"
  yEnter = yAxis.enter().append "g"
    .attr "id", "d3plus_graph_yticks"
    .call yStyle
  yEnter.selectAll("path").attr "fill", "none"
  yEnter.selectAll("line").call tickStyle, "y"
  yAxis.exit().transition().duration vars.data.timing
    .attr "opacity", 0
    .remove()

  # Style for both axes text labels
  labelStyle = (label, axis) ->
    label
      .attr "x",
        if axis is "x"
          vars.width.viz/2
        else
          -(vars.axes.height/2+vars.axes.margin.top)
      .attr "y",
        if axis is "x"
          vars.height.viz - vars[axis].label.height/2 - vars[axis].label.padding
        else
          vars[axis].label.height/2 + vars[axis].label.padding
      .attr "transform", if axis is "y" then "rotate(-90)" else null
      .attr "font-family", vars[axis].label.font.family.value
      .attr "font-weight", vars[axis].label.font.weight
      .attr "font-size", vars[axis].label.font.size+"px"
      .attr "fill", vars[axis].label.font.color
      .style "text-anchor", "middle"
      .attr "dominant-baseline", "central"

  for axis in ["x","y"]

    if vars[axis].grid.value
      gridData = vars[axis].ticks.values
    else
      gridData = []
      if vars[axis].ticks.values.indexOf(0) >= 0 and vars[axis].axis.value
        gridData = [0]

    # Draw Axis Grid Lines
    grid = plane.selectAll("g#d3plus_graph_"+axis+"grid").data [0]
    grid.enter().append "g"
      .attr "id", "d3plus_graph_"+axis+"grid"
    lines = grid.selectAll("line")
      .data gridData, (d, i) ->
        if d.constructor is Date then d.getTime() else d
    lines.transition().duration vars.draw.timing
      .call tickPosition, axis
      .call tickStyle, axis, true
    lines.enter().append "line"
      .style "opacity", 0
      .call tickPosition, axis
      .call tickStyle, axis, true
      .transition().duration vars.draw.timing
        .delay vars.draw.timing/2
        .style "opacity", 1
    lines.exit().transition().duration vars.draw.timing/2
      .style "opacity", 0
      .remove()

    axisLabel = vars[axis].label.fetch vars
    labelData = if axisData and axisLabel then [0] else []
    affixes   = vars.format.affixes.value[vars[axis].value]
    if axisLabel and !vars[axis].affixes.value and affixes
      sep = vars[axis].affixes.separator.value
      if sep is true
        sep = ["[","]"]
      else if sep is false
        sep = ["",""]
      axisLabel += " "+sep[0]+affixes[0]+" "+affixes[1]+sep[1]

    # Draw Axis Text Label
    label = vars.group.selectAll("text#d3plus_graph_"+axis+"label")
      .data labelData
    label.text axisLabel
      .transition().duration vars.draw.timing
        .call labelStyle, axis
    label.enter().append("text")
      .attr "id", "d3plus_graph_"+axis+"label"
      .text axisLabel
      .call labelStyle, axis
    label.exit().transition().duration vars.data.timing
      .attr "opacity", 0
      .remove()

  for axis in ["x","y"]

    lineGroup = plane.selectAll("g#d3plus_graph_"+axis+"_userlines").data [0]

    lineGroup.enter().append "g"
      .attr "id", "d3plus_graph_"+axis+"_userlines"

    # Draw Axis Lines
    domain   = vars[axis].scale.viz.domain()
    domain   = domain.slice().reverse() if axis is "y"
    textData = []
    lineData = []
    userLines = vars[axis].lines.value or []

    for line in userLines
      d = if validObject(line) then line.position else line
      unless isNaN(d)
        d = parseFloat(d)
        if d > domain[0] and d < domain[1]
          d = unless validObject(line) then {"position": d} else line
          d.coords =
            line: vars[axis].scale.viz(d.position)
          lineData.push d
          if d.text

            d.axis    = axis
            d.padding = vars[axis].lines.font.padding.value * 0.5
            d.align   = vars[axis].lines.font.align.value

            position = vars[axis].lines.font.position.text
            textPad  = if position is "middle" then 0 else d.padding * 2
            textPad  = -textPad if position is "top"

            if axis is "x"
              textPos  = if d.align is "left" then vars.axes.height else if d.align is "center" then vars.axes.height/2 else 0
              textPos -= d.padding * 2 if d.align is "left"
              textPos += d.padding * 2 if d.align is "right"
            else
              textPos  = if d.align is "left" then 0 else if d.align is "center" then vars.axes.width/2 else vars.axes.width
              textPos -= d.padding * 2 if d.align is "right"
              textPos += d.padding * 2 if d.align is "left"

            d.coords.text = {}
            d.coords.text[if axis is "x" then "y" else "x"] = textPos
            d.coords.text[axis] = vars[axis].scale.viz(d.position)+textPad

            d.transform = if axis is "x" then "rotate(-90,"+d.coords.text.x+","+d.coords.text.y+")" else null

            textData.push d

    lines = lineGroup.selectAll "line.d3plus_graph_"+axis+"line"
      .data lineData, (d) -> d.position

    lines.enter().append "line"
      .attr "class", "d3plus_graph_"+axis+"line"
      .attr "opacity", 0
      .call lineStyle, axis

    lines.transition().duration vars.draw.timing
      .attr "opacity", 1
      .call lineStyle, axis

    lines.exit().transition().duration vars.draw.timing
      .attr "opacity", 0
      .remove()

    linetexts = lineGroup.selectAll "text.d3plus_graph_"+axis+"line_text"
      .data textData, (d) -> d.position

    linetexts.enter().append "text"
      .attr "class", "d3plus_graph_"+axis+"line_text"
      .attr "id", (d) ->
        id = d.position+""
        id = id.replace("-", "neg")
        id = id.replace(".", "p")
        "d3plus_graph_"+axis+"line_text_"+id
      .attr "opacity", 0
      .call lineFont, axis

    linetexts
      .text (d) -> d.text
      .transition().duration vars.draw.timing
      .attr "opacity", 1
      .call lineFont, axis

    linetexts.exit().transition().duration vars.draw.timing
      .attr "opacity", 0
      .remove()

    rectStyle = (rect) ->

      getText  = (d) ->
        id = d.position+""
        id = id.replace("-", "neg")
        id = id.replace(".", "p")
        plane.select("text#d3plus_graph_"+d.axis+"line_text_"+id).node().getBBox()

      rect
        .attr "x", (d) -> getText(d).x - d.padding
        .attr "y", (d) -> getText(d).y - d.padding
        .attr "transform"  , (d) -> d.transform
        .attr "width", (d) -> getText(d).width + (d.padding * 2)
        .attr "height", (d) -> getText(d).height + (d.padding * 2)
        .attr "fill", vars.axes.background.color

    rectData = if vars[axis].lines.font.background.value then textData else []

    lineRects = lineGroup.selectAll "rect.d3plus_graph_"+axis+"line_rect"
      .data rectData, (d) -> d.position

    lineRects.enter().insert("rect", "text.d3plus_graph_"+axis+"line_text")
      .attr "class", "d3plus_graph_"+axis+"line_rect"
      .attr "pointer-events", "none"
      .attr("opacity", 0).call rectStyle

    lineRects.transition().delay vars.draw.timing
      .each "end", (d) ->
        d3.select(this).transition().duration vars.draw.timing
          .attr("opacity", 1).call rectStyle

    lineRects.exit().transition().duration vars.draw.timing
      .attr("opacity", 0).remove()

  return
