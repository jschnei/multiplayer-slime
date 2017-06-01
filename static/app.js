System.register("app", ["socket.io-client"], function (exports_1, context_1) {
    "use strict";
    var __moduleName = context_1 && context_1.id;
    var io, FPS, GAME_WIDTH, GAME_HEIGHT, PIXELS_PER_UNIT, COURT_Y, SLIME_RADIUS, BALL_RADIUS, MAX_VELOCITY_X, MAX_VELOCITY_Y, NUM_PLAYERS, BUFFER, NetworkGame;
    return {
        setters: [
            function (io_1) {
                io = io_1;
            }
        ],
        execute: function () {
            FPS = 50;
            GAME_WIDTH = 730;
            GAME_HEIGHT = GAME_WIDTH / 2;
            PIXELS_PER_UNIT = GAME_WIDTH / 1000;
            COURT_Y = 4 * GAME_HEIGHT / 5;
            SLIME_RADIUS = 50;
            BALL_RADIUS = 15;
            MAX_VELOCITY_X = 15;
            MAX_VELOCITY_Y = 11;
            NUM_PLAYERS = 2;
            BUFFER = 3;
            (function (NetworkGame) {
                var gameState;
                var canvas;
                var ctx;
                var interval = 1000 / FPS;
                var lastTime = (new Date()).getTime();
                var currentTime = 0;
                var curFrame = 0;
                var socket = io();
                var myId = -1;
                var inputs;
                var Input;
                (function (Input) {
                    Input[Input["Left"] = 0] = "Left";
                    Input[Input["Up"] = 1] = "Up";
                    Input[Input["Right"] = 2] = "Right";
                    Input[Input["Down"] = 3] = "Down";
                })(Input = NetworkGame.Input || (NetworkGame.Input = {}));
                var NUM_INPUTS = Object.keys(Input).length / 2;
                var KEY_MAP = {
                    37: Input.Left,
                    38: Input.Up,
                    39: Input.Right,
                    40: Input.Down
                };
                function newPlayerInput(copy) {
                    var returnState = {};
                    for (var i = 0; i < NUM_INPUTS; i++) {
                        if (copy == undefined) {
                            returnState[i] = false;
                        }
                        else {
                            returnState[i] = copy[i];
                        }
                    }
                    return returnState;
                }
                var playerInput = {};
                addEventListener("keydown", function (e) {
                    if (e.keyCode in KEY_MAP) {
                        playerInput[KEY_MAP[e.keyCode]] = true;
                    }
                }, false);
                addEventListener("keyup", function (e) {
                    if (e.keyCode in KEY_MAP) {
                        playerInput[KEY_MAP[e.keyCode]] = false;
                    }
                }, false);
                function emitKeys() {
                    socket.emit('update', { frame: curFrame,
                        player: myId,
                        inputs: playerInput });
                    inputs[curFrame + BUFFER][myId] = newPlayerInput(playerInput);
                }
                function haveInputs(frame) {
                    return (inputs[0][frame] != null && inputs[1][frame] != null);
                }
                function loop() {
                    window.requestAnimationFrame(loop);
                    currentTime = (new Date()).getTime();
                    var delta = currentTime - lastTime;
                    if (delta > interval) {
                        if (haveInputs(curFrame)) {
                            gameState.update(inputs[curFrame]);
                            gameState.render(ctx, canvas);
                            emitKeys();
                            lastTime = currentTime;
                            curFrame += 1;
                        }
                        else {
                            console.log("Waiting for input for frame " + curFrame);
                        }
                    }
                }
                function initializeGame() {
                    var gameDiv = document.getElementById('game');
                    canvas = document.createElement('canvas');
                    canvas.width = 730;
                    canvas.height = 365;
                    gameDiv.appendChild(canvas);
                    ctx = canvas.getContext("2d");
                    gameState = new SlimeVolleyball.Game();
                    for (var i = 0; i < BUFFER; i++) {
                        for (var j = 0; j < NUM_PLAYERS; j++) {
                            inputs[i][j] = newPlayerInput();
                        }
                    }
                }
                socket.on('init', function (msg) {
                    myId = msg.playerId;
                });
                socket.on('start', function (msg) {
                    loop();
                });
                socket.on('update', function (msg) {
                    inputs[msg.frame + BUFFER][msg.player] = msg.inputs;
                });
            })(NetworkGame || (NetworkGame = {}));
        }
    };
});
System.register("SlimeVolleyball", ["./app.ts"], function (exports_2, context_2) {
    "use strict";
    var __moduleName = context_2 && context_2.id;
    var SlimeVolleyball;
    return {
        setters: [
            function (_1) {
            }
        ],
        execute: function () {
            (function (SlimeVolleyball) {
                var Input = NetworkGame.Input;
                var Game = (function () {
                    function Game() {
                        this.slimes = [new Slime(SLIME_RADIUS, '#f00', 0, 495, this),
                            new Slime(SLIME_RADIUS, '#0f0', 505, 1000, this)];
                        this.ball = new Ball(BALL_RADIUS, '#ff0', this);
                        this.initRound(true);
                    }
                    Game.prototype.initRound = function (server) {
                        this.ball.x = server ? 200 : 800;
                        this.ball.y = 200;
                        this.ball.velocityX = 0;
                        this.ball.velocityY = 0;
                        this.slimes[0].x = 200;
                        this.slimes[0].y = 0;
                        this.slimes[0].velocityX = 0;
                        this.slimes[0].velocityY = 0;
                        this.slimes[1].x = 800;
                        this.slimes[1].y = 0;
                        this.slimes[1].velocityX = 0;
                        this.slimes[1].velocityY = 0;
                    };
                    Game.prototype.update = function (inputs) {
                        for (var id = 0; id < NUM_PLAYERS; id++) {
                            var keys = inputs[id];
                            var slime = this.slimes[id];
                            if (keys[Input.Left]) {
                                if (keys[Input.Right]) {
                                    slime.velocityX = 0;
                                }
                                else {
                                    slime.velocityX = -8;
                                }
                            }
                            else if (keys[Input.Right]) {
                                slime.velocityX = 8;
                            }
                            else {
                                slime.velocityX = 0;
                            }
                            if (slime.y == 0 && keys[Input.Up]) {
                                slime.velocityY = 18;
                            }
                        }
                        this.slimes.forEach(function (slime) {
                            slime.update();
                        });
                        this.ball.update();
                    };
                    Game.prototype.render = function (ctx, canvas) {
                        ctx.clearRect(0, 0, canvas.width, canvas.height);
                        var courtHeight = GAME_HEIGHT / 5;
                        ctx.fillStyle = '#0077ff';
                        ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT - courtHeight);
                        ctx.fillStyle = '#ca6';
                        ctx.fillRect(0, GAME_HEIGHT - courtHeight, GAME_WIDTH, courtHeight);
                        ctx.fillStyle = '#fff';
                        ctx.fillRect(GAME_WIDTH / 2 - 2, 7 * GAME_HEIGHT / 10, 4, GAME_HEIGHT / 10 + 5);
                        this.slimes.forEach(function (slime) {
                            slime.render(ctx, canvas);
                        });
                        this.ball.render(ctx, canvas);
                    };
                    return Game;
                }());
                SlimeVolleyball.Game = Game;
                var Slime = (function () {
                    function Slime(radius, color, leftLimit, rightLimit, game) {
                        this.radius = radius;
                        this.color = color;
                        this.leftLimit = leftLimit;
                        this.rightLimit = rightLimit;
                        this.game = game;
                    }
                    Slime.prototype.render = function (ctx, canvas) {
                        var xPix = this.x * PIXELS_PER_UNIT;
                        var yPix = COURT_Y - (this.y * PIXELS_PER_UNIT);
                        var radiusPix = this.radius * PIXELS_PER_UNIT;
                        ctx.fillStyle = this.color;
                        ctx.beginPath();
                        ctx.arc(xPix, yPix, radiusPix, Math.PI, 2 * Math.PI);
                        ctx.fill();
                    };
                    Slime.prototype.update = function () {
                        if (this.velocityX != 0) {
                            this.x += this.velocityX;
                            if (this.x - this.radius < this.leftLimit) {
                                this.x = this.leftLimit + this.radius;
                            }
                            else if (this.x + this.radius > this.rightLimit) {
                                this.x = this.rightLimit - this.radius;
                            }
                        }
                        if (this.velocityY != 0 || this.y > 0) {
                            this.y += this.velocityY;
                            this.velocityY -= 1.2;
                            if (this.y < 0) {
                                this.y = 0;
                                this.velocityY = 0;
                            }
                        }
                    };
                    return Slime;
                }());
                var Ball = (function () {
                    function Ball(radius, color, game) {
                        this.radius = radius;
                        this.color = color;
                        this.game = game;
                    }
                    Ball.prototype.render = function (ctx, canvas) {
                        var xPix = this.x * PIXELS_PER_UNIT;
                        var yPix = COURT_Y - (this.y * PIXELS_PER_UNIT);
                        var radiusPix = this.radius * PIXELS_PER_UNIT + 2;
                        ctx.fillStyle = this.color;
                        ctx.beginPath();
                        ctx.arc(xPix, yPix, radiusPix, 0, 2 * Math.PI);
                        ctx.fill();
                    };
                    Ball.prototype.update = function () {
                        var _this = this;
                        this.x += this.velocityX;
                        this.y += this.velocityY;
                        this.velocityY += -.5;
                        if (this.velocityY < -MAX_VELOCITY_Y) {
                            this.velocityY = -MAX_VELOCITY_Y;
                        }
                        this.game.slimes.forEach(function (slime) { _this.collideSlime(slime); });
                        if (this.x - this.radius < 0) {
                            this.x = this.radius;
                            this.velocityX = -this.velocityX;
                        }
                        else if (this.x + this.radius > 1000) {
                            this.x = 1000 - this.radius;
                            this.velocityX = -this.velocityX;
                        }
                        if (this.y < 0) {
                            if (this.x > 500) {
                                this.game.initRound(true);
                            }
                            else {
                                this.game.initRound(false);
                            }
                        }
                    };
                    Ball.prototype.collideSlime = function (slime) {
                        var dx = this.x - slime.x;
                        var dy = this.y - slime.y;
                        var dist = Math.sqrt(dx * dx + dy * dy);
                        var dVelocityX = this.velocityX - slime.velocityX;
                        var dVelocityY = this.velocityY - slime.velocityY;
                        if (dy > 0 && dist < this.radius + slime.radius) {
                            var oldBall = { x: this.x,
                                y: this.y,
                                velocityX: this.velocityX,
                                velocityY: this.velocityY };
                            this.x = slime.x + (slime.radius + this.radius) * dx / dist;
                            this.y = slime.y + (slime.radius + this.radius) * dy / dist;
                            var something = (dx * dVelocityX + dy * dVelocityY) / dist;
                            if (something <= 0) {
                                this.velocityX += slime.velocityX - 1.92 * dx * something / dist;
                                this.velocityY += slime.velocityY - 1.92 * dy * something / dist;
                                if (this.velocityX < -MAX_VELOCITY_X)
                                    this.velocityX = -MAX_VELOCITY_X;
                                else if (this.velocityX > MAX_VELOCITY_X)
                                    this.velocityX = MAX_VELOCITY_X;
                                if (this.velocityY < -MAX_VELOCITY_Y)
                                    this.velocityY = -MAX_VELOCITY_Y;
                                else if (this.velocityY > MAX_VELOCITY_Y)
                                    this.velocityY = MAX_VELOCITY_Y;
                            }
                        }
                    };
                    return Ball;
                }());
            })(SlimeVolleyball || (SlimeVolleyball = {}));
        }
    };
});
//# sourceMappingURL=app.js.map