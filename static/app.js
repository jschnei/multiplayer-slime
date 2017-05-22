var main(){
    
    //socket.io initialization
    var socket = io.connect('http://' + document.domain + ':' + location.port);
    var room = location.pathname;
    

    socket.on('connect', function() {
        socket.emit('init', {room: room});
    });

    socket.on('update', function(msg) {
        if(!isPuzzle) return;
        if(msg['uid']!==puzzle.uid){
            setAlert('Puzzle out of date; please refresh page');
            return;
        }

        var cell = msg['cell'];
        var value = msg['value'];

        gridTextDOM[cell].text(value);

        greyOutClue(puzzle.grid[cell].acrossClue);
        greyOutClue(puzzle.grid[cell].downClue);

        if(msg['solved']){
            setAlert('Good job! You solved the puzzle!');
        }
    });

    socket.on('update_all', function(msg) {
        if(!isPuzzle) return;

        if(msg['uid']!==puzzle.uid){
            setAlert('Puzzle out of date; please refresh page.');
            return;
        }

        for(var i=0;i<gridDOM.length;i++){
            gridTextDOM[i].text(msg.data[i]);
        }

        for(var i=0;i<puzzle.clues.length;i++){
            greyOutClue(i);
        }

        if(msg['solved']){
            setAlert('Good job! You solved the puzzle!');
        }
    });

    socket.on('update_puzzle', function(puzzleData) {
        initialize(puzzleData);
    });

    socket.on('error', function(message) {
        switch(message.code){
            case 'REFR':
                setAlert('Puzzle out of date; please refresh page');
                break;

            default:
                break;
        }
    });
};

$(document).ready(main);