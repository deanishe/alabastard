(($) ->

) jQuery


class @Weather

  constructor: () ->

    ###
                               .8888b oo
                               88   "
    .d8888b. .d8888b. 88d888b. 88aaa  dP .d8888b.
    88'  `"" 88'  `88 88'  `88 88     88 88'  `88
    88.  ... 88.  .88 88    88 88     88 88.  .88
    `88888P' `88888P' dP    dP dP     dP `8888P88
                                              .88
                                          d8888P
    ###

    # Map the icons specified by forecast.io
    # to ones available in the font
    # @weatherIconClassMapping =
    #   'rain'                : 'wi-rain'
    #   'snow'                : 'wi-snow'
    #   'fog'                 : 'wi-fog'
    #   'cloudy'              : 'wi-cloudy'
    #   'wind'                : 'wi-windy'
    #   'clear-day'           : 'wi-day-sunny'
    #   'mostly-clear-day'    : 'wi-day-sunny-overcast'
    #   'partly-cloudy-day'   : 'wi-day-cloudy'
    #   'clear-night'         : 'wi-night-clear'
    #   'partly-cloudy-night' : 'wi-night-cloudy'
    #   'unknown'             : 'wi-cloud-refresh'

    # level -> max speed in kph, i.e. force 2 is between
    # 5.5 and 11.9 kph
    @beaufortWindSpeedMapping =
      0  : 1.1
      1  : 5.5
      2  : 11.9
      3  : 19.7
      4  : 28.7
      5  : 38.8
      6  : 49.9
      7  : 61.8
      8  : 74.6
      9  : 88.1
      10 : 102.4
      11 : 117.4

  # Main entry point
  run: () ->
    console.log '[weather] running ...'

    # Add stylesheet
    $('head').append '<link rel="stylesheet" type="text/css" href="../css/weather.css" />'

    # All percentages
    $( '.percent.value' ).each (i, e) =>
      p = $(e).data 'percent'
      pc = (p * 100).toFixed(0) + '%'
      $(e).html pc

    # All wind direction icons
    $('.forecast .wind').each (i, elem) =>
      elem = $(elem)
      bearing = elem.data 'wind-bearing'
      wc = @getWindDirectionIconClass bearing
      console.log('[wind] bearing=' + bearing + ', wc=' + wc)
      elem.find('.bearing').html ''
      elem.find('i.icon').addClass wc

    # Summary icons
    $('.forecast .summary').each (i, div) =>
      div = $(div)
      icon = div.data('icon')
      div.find('i.icon').addClass('wi wi-forecast-io-' + icon)

    # Add times to non-current forecast titles
    $('section.later').each (i, s) =>
      s = $(s)
      s.find('.forecast').each (i, f) =>
        $(f).find('.summary').each (i, div) =>
          div = $(div)
          d = @timestampToDate div.data('time')

          div.find('time').each (i, t) =>
            t = $(t)
            t.attr('datetime', d)
            t.html @formatDate(d)

    # Make temperatures integers
    $('.forecast .temp').each (i, div) =>
      div = $( div )
      t = div.data 'temp'
      i = t.toFixed(0)
      if i == '-0'
        i = 0
      div.find('.value').html(i)

    # No precipitation
    $('.forecast .precipitation .summary').each (i, elem) =>
      elem = $(elem)
      if elem.data('probability') == 0
        elem.html 'dry'

    # Wind direction
    $('.forecast .wind').each (i, tr) =>
      tr = $( tr )
      tr.find('.speed').each (i, div) =>
        div = $(div)
        div.html(@metresPerSecondToKph(div.data('speed')) + ' kph')
      # TODO: Add warning colours?

    # Warning colours
    $('.forecast').each (i, section) =>
      section = $(section)
      # Rain
      section.find('tr.precipitation').each (i, tr) =>
        tr = $(tr)
        type = tr.data('type')
        intensity = tr.data('intensity')
        probability = tr.data('probability')
        level = @getPrecipitationWarnLevel(probability, intensity)
        console.log """[precipitation] type=#{type}, intensity=#{intensity}, probability=#{probability}, level=#{level}"""
        tr.find('i.icon').each (i, icon) =>
          if level == 0
            return
          else
            $(icon).addClass('wi wi-rain warn' + level)
      # Wind
      section.find('tr.wind').each (i, tr) =>
        tr = $(tr)
        speed = @metresPerSecondToKph tr.data('speed')
        level = @getWindWarnLevel(speed)
        console.log """[wind] speed=#{speed}, level=#{level}"""
        tr.find('i.icon').each (i, icon) =>
          if level > 0
            $(icon).addClass('warn' + level)

  ###
        dP            dP
        88            88
  .d888b88 .d8888b. d8888P .d8888b.
  88'  `88 88'  `88   88   88'  `88
  88.  .88 88.  .88   88   88.  .88
  `88888P8 `88888P8   dP   `88888P8

  ###

  #---------------------------------------
  # Helpers

  # Sort helper to sort digits numerically, not alphabetically
  sortNumber: (a, b) ->
    a - b

  # Sort event objects by `time` member
  sortEvents: (e1, e2) ->
    e1.time - e2.time

  # Weather Icons class for the prevailing cloud cover
  getWeatherIconClass: (data) ->
    return @weatherIconClassMapping['unknown'] unless data
    if data.icon.indexOf('cloudy') > -1
      if data.cloudCover < 0.25
        @weatherIconClassMapping["clear-day"]
      else if data.cloudCover < 0.5
        @weatherIconClassMapping["mostly-clear-day"]
      else if data.cloudCover < 0.75
        @weatherIconClassMapping["partly-cloudy-day"]
      else
        @weatherIconClassMapping["cloudy"]
    else
      @weatherIconClassMapping[data.icon]

  # CSS class for moon phase icon for the given day
  getMoonIconClass: (data) ->
    phases = (key for key of @moonIconClassMapping)
    phases.sort()
    thisPhase = null
    for phase, i in phases
      if data.moonPhase == phase
        thisPhase = phase
        break
      if data.moonPhase < phase
        thisPhase = phase
        break

    if thisPhase
      console.log('Moon phase : ' + thisPhase)
      return @moonIconClassMapping[thisPhase]

    return ''

  # CSS class for wind direction icon for given forecast
  getWindDirectionIconClass: (bearing) ->
    return """wi wi-wind from-#{ bearing }-deg"""

  # 0 (calm) to 12 (hurricane)
  getWindForce: (windSpeed) ->
    numbers = (key for key of @beaufortWindSpeedMapping)
    # windSpeed = data.windSpeed * 3.6  # convert m/s to kph
    windForce = null
    for scaleNo in numbers
      limit = @beaufortWindSpeedMapping[scaleNo]
      # console.log('wind force ' + scaleNo + ' limit = ' + limit + ' kph')
      if windSpeed <= limit
        windForce = scaleNo
        break

    if windForce is null
      windForce = 12

    # console.log('windSpeed ' + windSpeed + ' kph = force ' + windForce)
    return windForce

  getWindForceIconClass: (data) ->
    windForce = @getWindForce data
    # console.log('windForce = ' + windForce)
    return """wi-beaufort-#{ windForce }"""

  # Return string probability of rain, e.g. '10%' or 'dry' (=0%)
  getRainProbability: (data) ->
    if data.precipProbability == 0
      return 'dry'

    return (data.precipProbability * 100).toFixed(0) + '%'

  # Return string description or how heavy the rain is
  getRainIntensity: (data) ->
    if data.precipProbability == 0
      return ''
    intensity   = 'v. light'
    if data.precipIntensity > 0.017
      intensity = 'light'
    if data.precipIntensity > 0.1
      intensity = 'moderate'
    if data.precipIntensity > 0.4
      intensity = 'heavy'
    return intensity

  getPrecipitationWarnLevel: (probability, intensity) ->
    if probability == 0
      return 0

    level = 0
    p = probability
    i = intensity
    if p >= 0.9
      level = 5
    else if p >= 0.7
      level = 4
    else if p >= 0.5
      level = 3
    else if p >= 0.3
      level = 2
    else if p >= 0.1
      level = 1

    # Adjust points for intensity
    if i < 0.017
      level -= 1
    else if i > 0.4
      level += 2
    else if i > 0.2
      level += 1

    if level > 5
      level = 5

    return level

  getWindWarnLevel: (windSpeed) ->
    windForce = @getWindForce windSpeed
    console.log """[wind] speed=#{windSpeed}, force=#{windForce}"""
    if windForce > 5
      return 5
    if windForce > 4
      return 4
    if windForce > 2
      return 3
    if windForce > 1
      return 2
    if windForce > 0
      return 1

    return 0

  # Return list of warning objects if wind or rain is too extreme
  getWarnings: (data) ->
    ###
    Returns list of objects:

    w:
      type: 'rain' or 'wind'
      level: 1-5 for rain, 0-12 for wind
    ###

    warnings = []

    #----------------------------------------
    # Rain

    level = 0
    p = data.precipProbability
    i = data.precipIntensity
    if p >= 0.9
      level = 5
    else if p >= 0.7
      level = 4
    else if p >= 0.5
      level = 3
    else if p >= 0.3
      level = 2
    else if p >= 0.1
      level = 1

    # Adjust points for intensity
    if i < 0.017
      level -= 1
    else if i > 0.4
      level += 2
    else if i > 0.2
      level += 1

    if level > 5
      level = 5

    if level > 0
      w =
        type: 'rain'
        level: level
      warnings.push w

    #----------------------------------------
    # Wind

    windForce = @getWindForce data
    if windForce > 2
      w =
        type: 'wind'
        level: windForce
      warnings.push w

    return warnings

  # Return 0 (dry) to 5 (pissing)
  getRainDangerLevel: (data) ->
    for w in @getWarnings data
      if w.type == 'rain'
        return w.level
    return 0

  # Return 0 (calm) to 12 (hurricane). Does not return values
  # beween zero and the danger threshold, e.g. if windforce < 3,
  # danger level will be zero.
  getWindDangerLevel: (data) ->
    for w in @getWarnings data
      if w.type == 'wind'
        return w.level
    return 0

  # Return string description of wind speed
  getWind: (data) ->
    windSpeed = data.windSpeed * 3.6  # convert m/s to kph
    return windSpeed.toFixed(0) + ' kph'

  # Convert UNIX timestamp to JavaScript Date (localtime)
  timestampToDate: (utcTime) ->
    date  = new Date(0)
    date.setUTCSeconds(utcTime)
    date

  # Return HH:MM time for Date
  formatDate: (date) ->
    return date.getHours() + ':' + '0' + date.getMinutes()

  metresPerSecondToKph: (n) ->
    return (n * 3.6).toFixed(0)

  ###
                                   dP                   oo
                                   88
  88d888b. .d8888b. 88d888b. .d888b88 .d8888b. 88d888b. dP 88d888b. .d8888b.
  88'  `88 88ooood8 88'  `88 88'  `88 88ooood8 88'  `88 88 88'  `88 88'  `88
  88       88.  ... 88    88 88.  .88 88.  ... 88       88 88    88 88.  .88
  dP       `88888P' dP    dP `88888P8 `88888P' dP       dP dP    dP `8888P88
                                                                         .88
                                                                     d8888P
  ###


  #----------------------------------------------------
  # Component widgets

  # Render a Weather Icons icon of class cssClass
  renderIcon: (cssClass) ->
    """<i class="wi #{cssClass}"></i>"""

  # Render a box with wind direction icon and speed
  renderWind: (data) ->
    """
    <div class="windbox">
      <div class="wind-direction">#{ @renderIcon @getWindDirectionIconClass data }</div>
      <div class="wind-speed">#{ @getWind data }</div>
    </div>
    """

  # Render a box with wind direction icon and speed
  renderWindDaily: (data) ->
    """
    <span class="wind-direction">#{ @renderIcon @getWindDirectionIconClass data }</span>
    <span class="wind-speed">#{ @getWind data }</span>
    """

  # (unused) Render a list of rain and/or wind warnings
  # Replaced with coloured forecast/wind icons
  renderWarnings: (data) ->
    warnings = @getWarnings data
    output = []
    for w in warnings
      if w.type == 'rain'
        output.push """\
          <li class="warning rain-#{ w.level }">#{ @renderIcon 'wi-rain' }</li>
          """
      else if w.type == 'wind'
        output.push """\
            <li class="warning">#{ @renderIcon @getWindForceIconClass(data) }</li>
          """

    if output.length
      """
      <ul class="warnings">
        #{ output.join('') }
      </ul>
      """
    else ""

console.log '[weather] loaded'
