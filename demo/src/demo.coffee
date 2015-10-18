# function that converts from a particular data format into the generic one
# expected by the plugin
convert = (rawData) ->
  value = 0
  for state in ['RUNNABLE', 'BLOCKED', 'TIMED_WAITING', 'WAITING']
    value += rawData.c[state] if not isNaN(rawData.c[state])

  timeElapsed = new Date()
  timeElapsed.setSeconds(value)
  timeFormat = countdown.DAYS | countdown.HOURS | countdown.MINUTES | countdown.SECONDS
  node =
    name: rawData.n,
    value: value,
    time: countdown(new Date(), timeElapsed, timeFormat)
    children: []

  # the a field is the list of children
  return node if not rawData.a
  for child in rawData.a
    subTree = convert(child)
    if subTree
      node.children.push(subTree)
  node

d3.json "data/profile.json", (err, data) ->
  profile = convert(data.profile)
  tooltip = (d) -> "#{d.name} <br /><br />
    #{d.value} samples<br />
    #{((d.value / profile.value) * 100).toFixed(2)}% of total"
  flameGraph = d3.flameGraph('#d3-flame-graph')
    .size([1200, 600])
    .cellHeight(20)
    .data(profile)
    .zoomEnabled(true)
    # .zoomAction((d) -> console.log(d))
    .tooltip(tooltip)
    .render()

  d3.select('#highlight')
    .on 'click', () ->
      nodes = flameGraph.select((d) -> /java\.util.*/.test(d.name))
      nodes.classed("highlight", (d, i) -> not d3.select(@).classed("highlight"))

  d3.select('#zoom')
    .on 'click', () ->
      # jump to the first java.util.concurrent method we can find
      node = flameGraph.select(((d) -> /java\.util\.concurrent.*/.test(d.name)), false)[0]
      flameGraph.zoom(node)

  # hacky way of implementing toggle behaviour, can't be bothered right now
  unhide = false
  d3.select('#hide')
    .on 'click', () ->
      flameGraph.hide ((d) -> /Unsafe\.park$/.test(d.name) or /Object\.wait/.test(d.name)), unhide
      unhide = !unhide