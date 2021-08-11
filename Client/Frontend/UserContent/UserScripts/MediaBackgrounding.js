// The below is needed because the script may not be web-packed into a bundle so it may be missing the run-once code

// MARK: - Include Once

if (!window.__firefox__) {
    window.__firefox__ = {};
}

if (!window.__firefox__.includeOnce) {
    window.__firefox__ = {};
    window.__firefox__.includeOnce = function(key, func) {
        var keys = {};
        if (!keys[key]) {
            keys[key] = true;
            func();
        }
    };
}


window.__firefox__.includeOnce("$<MediaBackgrounding>", function() {
    var visibilityState_Get = Object.getOwnPropertyDescriptor(Document.prototype, "visibilityState").get;
    var visibilityState_Set = Object.getOwnPropertyDescriptor(Document.prototype, "visibilityState").set;
    Object.defineProperty(Document.prototype, 'visibilityState', {
        enumerable: true,
        configurable: true,
        get: function() {
            var result = visibilityState_Get.call(this);
            if (result != "visible") {
                return "visible";
            }
            return result;
        },
        set: function(value) {
            visibilityState_Set.call(this, value);
        }
    });

    var pauseControl = HTMLVideoElement.prototype.pause;
    HTMLVideoElement.prototype.pause = function() {
        this.userHitPause = true;
        return pauseControl.call(this);
    }

    var playControl = HTMLVideoElement.prototype.play;
    HTMLVideoElement.prototype.play = function() {
        this.userHitPause = false;
        return playControl.call(this);
    }
    
    HTMLVideoElement.prototype.addPauseListener = function() {
        if (!this.pauseListener) {
            this.pauseListener = true;
            
            this.addEventListener("pause", function(e) {
                if (!this.userHitPause && visibilityState_Get.call(document) == "visible") {
                    var onVisibilityChanged = (e) => {
                        document.removeEventListener("visibilitychange", onVisibilityChanged);
                        
                        if (visibilityState_Get.call(document) != "visible" && !this.ended) {
                            playControl.call(this);
                        }
                    };
                    
                    document.addEventListener("visibilitychange", onVisibilityChanged);
                    
                    setTimeout(function() {
                        document.removeEventListener("visibilitychange", onVisibilityChanged);
                    }, 2000);
                }
            }, false);
        }
        
        if (!this.presentationModeListener) {
            this.presentationModeListener = true;
            
            this.addEventListener('webkitpresentationmodechanged', function(e) {
                e.stopPropagation();
            }, true);

            setTimeout(() => {
                this.webkitSetPresentationMode('picture-in-picture');
            }, 3000);
        }
    }
    
    function setupListener() {
        var m_css = document.createElement("style");
        m_css.type = "text/css";
        m_css.innerHTML = `.onElementInserted {
                               animation: __elementInserted 0.001s !important;
                               -o-animation: __elementInserted 0.001s !important;
                               -ms-animation: __elementInserted 0.001s !important;
                               -moz-animation: __elementInserted 0.001s !important;
                               -webkit-animation: __elementInserted 0.001s !important;
                           }
        
                           @keyframes __elementInserted {
                               from { opacity: 0.99; }
                               to { opacity: 1; }
                           }
                           @-moz-keyframes __elementInserted {
                               from { opacity: 0.99; }
                               to { opacity: 1; }
                           }
                           @-webkit-keyframes __elementInserted {
                               from { opacity: 0.99; }
                               to { opacity: 1; }
                           }
                           @-ms-keyframes __elementInserted {
                               from { opacity: 0.99; }
                               to { opacity: 1; }
                           }
                           @-o-keyframes __elementInserted {
                               from { opacity: 0.99; }
                               to { opacity: 1; }
                           }`;
        document.body.appendChild(m_css);

        insertion_event = function(event) {
            if (event.animationName == '__elementInserted') {
                event.target.className = event.target.className.replace(/\bonElementInserted\b/,'');
                document.dispatchEvent(new CustomEvent('elementInserted', {'target': event.target}));
            }
        }

        document.addEventListener('animationstart', insertion_event, false);
        document.addEventListener('MSAnimationStart', insertion_event, false);
        document.addEventListener('webkitAnimationStart', insertion_event, false);
    }
    
    window.onload = function() {
        setupListener();
        document.addEventListener('elementInserted', function(e) {
            if (e.target.constructor.name == 'HTMLVideoElement') {
                e.target.addPauseListener();
            }
        });
        
        document.querySelectorAll('video').forEach((e) => {
            e.addPauseListener();
        });
    };
});
