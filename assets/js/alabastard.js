
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
