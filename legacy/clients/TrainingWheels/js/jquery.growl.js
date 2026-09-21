(function($, undefined){
    var $container;
    var _fadeInTime;
    var _fadeOutTime;
    var _timeoutTime;

    var _timeouts = {};
    var _queue = [];

    var $style = $('<style />').text(' \
        .growl-container { \
            position: absolute; \
            top: 20px; \
            right: 20px; \
            padding: 0; \
            margin: 0; \
            text-align: right; \
        } \
        .growl-message { \
            background: #000; \
            background: rgba(0, 0, 0, 0.6); \
            color: #fff; \
            padding: 15px 5px; \
            margin: 10px; \
            -webkit-border-radius: 10px; \
            -moz-border-radius: 10px; \
            border-radius: 10px; \
            display: inline; \
            clear: both; \
            float: right; \
        } \
        .growl-close { \
            margin: 5px; \
        } \
    ');

    $.fn.growl = function(opts){
        opts = opts || {};
        $container = $(this)
            .addClass('growl-container')
            .on('click', '.growl-close', function(){
                $(this).parent().remove();
            })
            .on('mouseover', '.growl-message', function(){
                var $this = $(this);
                var timeout = _timeouts[$this.data('timeout')];
                clearTimeout(timeout);
            })
            .on('mouseout', '.growl-message', function(){
                var $this = $(this);
                var num = $(this).data('timeout');
                var timeout = setTimeout(function(){
                    $this.fadeOut(_fadeOutTime, function(){
                        $this.remove();
                    });
                }, _timeoutTime);

                _timeouts[num] = timeout;
            });

        _fadeInTime = opts.fadeInTime || 500;
        _fadeOutTime = opts.fadeOutTime || 500;
        _timeoutTime = opts.timeoutTime || 4000;

        $('body').append($style);

        return this;
    };

    $.fn.growl_add = function(message, opts){

        _queue.push({"message": message, "opts": opts});

        return this;
    };

    function _add(message, opts){
        opts = opts || {};

        var fadeInTime = opts.fadeInTime || _fadeInTime;
        var fadeOutTime = opts.fadeOutTime || _fadeOutTime;
        var timeoutTime = opts.timeoutTime || _timeoutTime;

        var $close = $('<span />', {'class': 'growl-close'})
            .text('x');

        var $li = $('<li />', {'class': 'growl-message'})
            .hide()
            .text(message);
            // .append($close);

        $container.append($li);

        var num = Math.random();
        var timeout = setTimeout(function(){
            $li.fadeOut(fadeOutTime, function(){
                $li.remove();
            });
        }, timeoutTime + fadeInTime);

        _timeouts[num] = timeout;

        $li.data('timeout', num)
            .fadeIn(fadeInTime);
    }

    setInterval(function(){
        if(_queue.length > 0){
            var message = _queue.pop();
            _add(message.message, message.opts);
        }
    }, 500);
})(jQuery);