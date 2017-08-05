const num FPS = 60;

const GAME_WIDTH = 730;
const GAME_HEIGHT = GAME_WIDTH / 2;
const PIXELS_PER_UNIT = GAME_WIDTH / 1000;
const COURT_Y = 4 * GAME_HEIGHT / 5;
const SLIME_RADIUS = 50;
const BALL_RADIUS = 15;

const MAX_VELOCITY_X = 15;
const MAX_VELOCITY_Y = 11;

const NUM_PLAYERS = 2;
const DEFAULT_BUFFER = 3;
const LOCAL_BUFFER = 2; // only change this if you want to simulate latency locally

const SERVER_PORT = 8018;