// Copied from minimax-tic-tac-toe/public/game.js
// This file was integrated into the Inception static website.

// The content is preserved exactly to allow playing the game and to view the code.

class GameController {
  constructor(uiManager) {
    this.ui = uiManager;
    this.reset();
    this.player = 1;
    this.ai = 2;
    this.stats = {
      elo: 1200,
      gamesPlayed: 0,
      wins: 0,
      losses: 0,
      draws: 0
    };
    this.eloHistory = [];
    this.loadStats();
    this.loadELOHistory();
    this.ui.updateELODisplay(this.stats.elo, 0);
    this.ui.updateStats(this.stats);
    this.ui.updateELOHistory(this.eloHistory);
  }

  reset() {
    this.board = Array(9).fill(0);
    this.currentPlayer = 1;
    this.gameStatus = 'playing';
    this.winner = null;
    this.ui.renderBoard(this.board, () => {}); // plateau vide, pas de clics
    this.ui.enableBoard(false);
    setTimeout(() => {
      this.ui.renderBoard(this.board, this.handleCellClick.bind(this));
      this.ui.showGameResult('', 0);
      this.ui.showPlayerTurn(true);
      this.ui.enableBoard(true);
    }, 50);
  }

  handleCellClick(idx) {
    if (this.board[idx] !== 0 || this.gameStatus !== 'playing') return;
    this.board[idx] = this.player;
    this.ui.renderBoard(this.board, this.handleCellClick.bind(this));
    if (this.checkWinner(this.player)) { this.endGame('win'); return; }
    if (this.isDraw()) { this.endGame('draw'); return; }
    this.currentPlayer = this.ai;
    this.ui.showPlayerTurn(false);
    setTimeout(() => this.handleAIMove(), 400);
  }

  handleAIMove() {
    const move = MinimaxAI.getBestMove(this.board, this.ai, this.player);
    if (move === -1) return;
    this.board[move] = this.ai;
    this.ui.renderBoard(this.board, this.handleCellClick.bind(this));
    if (this.checkWinner(this.ai)) { this.endGame('loss'); return; }
    if (this.isDraw()) { this.endGame('draw'); return; }
    this.currentPlayer = this.player;
    this.ui.showPlayerTurn(true);
  }

  checkWinner(player) {
    const b = this.board;
    const lines = [ [0,1,2],[3,4,5],[6,7,8], [0,3,6],[1,4,7],[2,5,8], [0,4,8],[2,4,6] ];
    return lines.some(([a,b1,c]) => b[a] === player && b[b1] === player && b[c] === player);
  }

  isDraw() { return this.board.every(cell => cell !== 0); }

  endGame(result) {
    this.gameStatus = result === 'draw' ? 'draw' : 'won';
    let eloChange = 0;
    const aiRating = 1500;
    let gameResult = 0.5;
    if (result === 'win') gameResult = 1; else if (result === 'loss') gameResult = 0;
    const kFactor = this.stats.gamesPlayed < 30 ? 32 : 16;
    let newElo = this.stats.elo;
    if (typeof window.ELOService !== 'undefined'){
      newElo = window.ELOService.calculateNewRating(this.stats.elo, aiRating, gameResult, kFactor);
    } else {
      const expected = 1 / (1 + Math.pow(10, (aiRating - this.stats.elo) / 400));
      newElo = Math.round(this.stats.elo + kFactor * (gameResult - expected));
    }
    eloChange = newElo - this.stats.elo;
    this.stats.elo = newElo;
    this.eloHistory.push({ elo: newElo, date: new Date().toISOString() });
    if (result === 'win') { this.stats.wins++; this.ui.showGameResult('Victoire !', eloChange); }
    else if (result === 'loss') { this.stats.losses++; this.ui.showGameResult('Défaite...', eloChange); }
    else { this.stats.draws++; this.ui.showGameResult('Match nul', eloChange); }
    this.stats.gamesPlayed++;
    this.ui.updateELODisplay(this.stats.elo, eloChange);
    this.ui.updateStats(this.stats);
    this.saveStats();
    this.saveELOHistory();
    this.ui.updateELOHistory(this.eloHistory);
    this.ui.enableBoard(false);
  }
  saveStats() { localStorage.setItem('ttt-stats', JSON.stringify(this.stats)); }
  saveELOHistory() { localStorage.setItem('ttt-elo-history', JSON.stringify(this.eloHistory)); }
  loadStats() { const s = localStorage.getItem('ttt-stats'); if (s) this.stats = JSON.parse(s); }
  loadELOHistory() { const h = localStorage.getItem('ttt-elo-history'); this.eloHistory = h ? JSON.parse(h) : [{ elo: this.stats.elo, date: new Date().toISOString() }]; }
}

class UIManager {
  enableBoard(enabled) { const boardDiv = document.getElementById('game-board'); Array.from(boardDiv.children).forEach(cell => { cell.style.pointerEvents = enabled ? 'auto' : 'none'; cell.style.opacity = enabled ? '1' : '0.6'; }); }
  renderBoard(board, onCellClick) { const boardDiv = document.getElementById('game-board'); boardDiv.innerHTML = ''; board.forEach((cell, idx) => { const div = document.createElement('div'); div.className = 'cell'; div.textContent = cell === 1 ? 'X' : cell === 2 ? 'O' : ''; div.onclick = () => onCellClick(idx); boardDiv.appendChild(div); }); }
  showGameResult(result, eloChange) { const status = document.getElementById('game-status'); status.textContent = result ? `${result}${eloChange ? ` (ELO ${eloChange > 0 ? '+' : ''}${eloChange})` : ''}` : ''; }
  showPlayerTurn(isPlayerTurn) { const status = document.getElementById('game-status'); if (!status.textContent) status.textContent = isPlayerTurn ? 'À vous de jouer !' : 'Tour de l’IA...'; }
  updateELODisplay(currentELO, change) { document.getElementById('elo-value').textContent = currentELO; }
  updateELOHistory(history) { const ul = document.getElementById('elo-history'); if (!ul) return; ul.innerHTML = ''; if (history.length > 0) { const item = history[history.length - 1]; const li = document.createElement('li'); const d = new Date(item.date); li.textContent = `Last game ${d.toLocaleDateString()} ${d.toLocaleTimeString()} : ${item.elo}`; ul.appendChild(li); } }
  updateStats(stats) { document.getElementById('games-played').textContent = `${stats.gamesPlayed} parties`; document.getElementById('wins').textContent = `${stats.wins} victoires`; document.getElementById('losses').textContent = `${stats.losses} défaites`; document.getElementById('draws').textContent = `${stats.draws} nuls`; }
}

class MinimaxAI { static getBestMove(board, ai = 2, human = 1) { let bestScore = -Infinity; let move = -1; for (let i = 0; i < 9; i++) { if (board[i] === 0) { board[i] = ai; const score = this.minimax(board, 0, false, ai, human); board[i] = 0; if (score > bestScore) { bestScore = score; move = i; } } } return move; }
  static minimax(board, depth, isMax, ai, human) { const winner = this.evaluateBoard(board, ai, human); if (winner !== null) return winner - depth; if (board.every(cell => cell !== 0)) return 0; if (isMax) { let best = -Infinity; for (let i = 0; i < 9; i++) { if (board[i] === 0) { board[i] = ai; best = Math.max(best, this.minimax(board, depth + 1, false, ai, human)); board[i] = 0; } } return best; } else { let best = Infinity; for (let i = 0; i < 9; i++) { if (board[i] === 0) { board[i] = human; best = Math.min(best, this.minimax(board, depth + 1, true, ai, human)); board[i] = 0; } } return best; } }
  static evaluateBoard(board, ai, human) { const lines = [ [0,1,2],[3,4,5],[6,7,8], [0,3,6],[1,4,7],[2,5,8], [0,4,8],[2,4,6] ]; for (const [a,b,c] of lines) { if (board[a] && board[a] === board[b] && board[a] === board[c]) { if (board[a] === ai) return 10; if (board[a] === human) return -10; } } return null; }
}

window.addEventListener('DOMContentLoaded', () => { const ui = new UIManager(); const game = new GameController(ui); document.getElementById('new-game').onclick = () => game.reset(); });
