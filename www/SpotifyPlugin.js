var exec = require('cordova/exec');
               
module.exports = {
    login : function(a,b,url) {
        let swap = url+'/swap';
        let refresh = url+ '/refresh';
        exec(
                     function() {},
                     function() {},
                     "SpotifyPlugin",
                     "login",
                     [a,b,swap,refresh]
                     )
    },
     auth : function(token,id,success,error){
                   exec(
                        success,
                        error,
                        "SpotifyPlugin",
                        "auth",
                        [token,id]
                        )
                   },
    play:function(val,success,error){
        exec(
                    success,
                    error,
                     "SpotifyPlugin",
                     "play",
                     [val]
                     )
    },
    pause : function(success,error){
        exec(
                    success,
                    error,
                     "SpotifyPlugin",
                     "pause",
                     []
                     )
    },
    next : function(success,error){
        exec(
                    success,
                    error,
                     "SpotifyPlugin",
                     "next",
                     []
                     )
    },
    prev : function(success,error){
        exec(
                    success,
                    error,
                     "SpotifyPlugin",
                     "prev",
                     []
                     )
    },
    logout : function(){
        exec(
                     function(){},
                     function(){},
                     "SpotifyPlugin",
                     "logout",
                     []
                     )
    },
    seek : function(val,success,error){
        exec(
                    success,
                    error,
                     "SpotifyPlugin",
                     "seek",
                     [val]
                     )
    },
    seekTo : function(val,success,error){
        exec(
                    success,
                    error,
                    "SpotifyPlugin",
                    "seekTo",
                    [val]
                    )
    },
    setVolume : function(val){
        exec(
                     function(){},
                     function(){},
                     "SpotifyPlugin",
                     "volume",
                     [val]
                     )
    },
    getPosition : function(){
        exec(
                     function(){},
                     function(){},
                     "SpotifyPlugin",
                     "getPosition",
                     []
                     )
    },
    getToken : function(success,error){
               exec(
                   success,// function(res){alert(res);},//res - TOKEN
                    error,//function(){console.log("error");},
                    "SpotifyPlugin",
                    "getToken",
                    []
                    )
    },

    Events : {
        onPlayerPlay : function(args){},
        onMetadataChanged :function(args){},
        onPrev : function(args){
            //arg[0] - action
        },
        onNext : function(args){
            //arg[0] - action
        },
        onPause : function(args){
            //arg[0] - action
        },
        onPlay : function(args){
            //arg[0] - action
        },
        onAudioFlush : function(arg){
            //arg[0] - position (ms)
        },
        onTrackChanged : function(arg){
            //arg[0] - action
        },
        onPosition : function(arg){
            //arg[0] - position ms
        },
        onVolumeChanged : function(arg){
            //arg - volume betwen 0.0 ....1.0
        },
         onLogedIn :function(arg){
            /* alert(arg); */
        },
        onDidNotLogin:function(arg){
            /* alert(arg); */
        },
        onPlayError :function(error){
            /* alert(error[0]); */ //error[0] - error message
        }
        
    }
    
};

