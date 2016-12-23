
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
