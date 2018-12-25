
// onload handler that supports IE versions < 9 as well as real browsers
function callOnLoad(func) {
  if (window.addEventListener) {
    window.addEventListener('load', func, false);
  } else if (window.attachEvent) {
    window.attachEvent('onload', func);
  } else {
    window.onload = func;
  }
}

function loadScript(url, callback) {
  var script = document.createElement('script');
  script.type = 'text/javascript';
  if (script.readyState) {  // IE
    script.onreadystatechange = function() {
      if (script.readyState === 'loaded' || script.readyState === 'complete') {
        script.onreadystatechange = null;
        callback();
      }
    };
  } else {  // other browsers
    script.onload = function() {
      callback();
    };
  }

  script.src = url;
  document.getElementsByTagName('body')[0].appendChild(script);
}

// return time since Date as human-readable text.
function relTime(dt) {
  var delta = new Date().getTime() - dt.getTime(),
    neg = false;

  if (delta < 0) {  // time is in future
    delta = -delta
  }

  var secs = 0,
    mins = 0,
    hours = 0,
    days = 0,
    weeks = 0,
    months = 0,
    years = 0,
    n = 0,
    s = '';

  secs = Math.floor(delta / 1000);
  mins = Math.floor(secs / 60);
  secs = secs % 60;
  hours = Math.floor(mins / 60);
  mins = mins % 60;
  days = Math.floor(hours / 24);
  hours = hours % 24;
  weeks = Math.floor(days / 7);
  days = days % 7;
  if (weeks > 7) {
    months = Math.floor(weeks / 4);
    weeks = weeks % 4;
  }
  years = Math.floor(months / 12);
  months = months % 12;
  // console.debug(`[reltime] ${years}y${months}m${weeks}w${days}d${hours}h${mins}m${secs}s`);

  if (years) {
    n = years;
    s = ' year';
  } else if (months) {
    n = months;
    s = ' month';
  } else if (weeks) {
    n = weeks;
    s = ' week';
  } else if (days) {
    n = days;
    s = ' day';
  } else if (hours) {
    n = hours;
    s = ' hour';
  } else if (mins) {
    n = mins;
    s = ' min';
  } else if (secs) {
    n = secs;
    s = ' sec';
  }

  if (n !== 1 && n !== -1) {
    s += 's';
  }

  if (neg) return 'in ' + n + s;

  return n + s + ' ago';
}
