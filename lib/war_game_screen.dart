import 'dart:math';

import 'package:flutter/material.dart';

class WarGameScreen extends StatefulWidget {
  const WarGameScreen({super.key});

  @override
  State<WarGameScreen> createState() => _WarGameScreenState();
}

class _WarGameScreenState extends State<WarGameScreen> {
  static const List<String> _suits = ['♠', '♥', '♦', '♣'];
  static const List<String> _ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
    'A'
  ];

  final Random _random = Random();

  String _playerCard = '';
  String _opponentCard = '';
  int _playerScore = 0;
  int _opponentScore = 0;
  int _round = 0;
  String _statusMessage = 'Pulsa "Jugar ronda" para comenzar.';

  int _rankValue(String card) {
    final rank = card.split(' ').first;
    return _ranks.indexOf(rank);
  }

  String _drawCard() {
    final suit = _suits[_random.nextInt(_suits.length)];
    final rank = _ranks[_random.nextInt(_ranks.length)];
    return '$rank $suit';
  }

  void _playRound() {
    final playerCard = _drawCard();
    final opponentCard = _drawCard();
    final playerValue = _rankValue(playerCard);
    final opponentValue = _rankValue(opponentCard);

    String status;
    int playerScore = _playerScore;
    int opponentScore = _opponentScore;

    if (playerValue > opponentValue) {
      status = '¡Ganaste la ronda!';
      playerScore++;
    } else if (playerValue < opponentValue) {
      status = 'El oponente gana la ronda.';
      opponentScore++;
    } else {
      status = '¡Guerra! Es un empate.';
    }

    setState(() {
      _playerCard = playerCard;
      _opponentCard = opponentCard;
      _playerScore = playerScore;
      _opponentScore = opponentScore;
      _round += 1;
      _statusMessage = status;
    });
  }

  void _resetGame() {
    setState(() {
      _playerCard = '';
      _opponentCard = '';
      _playerScore = 0;
      _opponentScore = 0;
      _round = 0;
      _statusMessage = 'Pulsa "Jugar ronda" para comenzar.';
    });
  }

  Widget _buildCard(String label, String cardText, Color accentColor) {
    final bool hasCard = cardText.isNotEmpty;
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: hasCard
                    ? Text(
                        cardText,
                        key: ValueKey(cardText),
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      )
                    : Icon(Icons.style_outlined, key: const ValueKey('placeholder'), size: 48, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego de Guerra'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ronda $_round', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tú: $_playerScore', style: const TextStyle(fontSize: 18)),
                        Text('Oponente: $_opponentScore', style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  _buildCard('Tu carta', _playerCard, accentColor),
                  _buildCard('Carta del oponente', _opponentCard, accentColor),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _playRound,
                    icon: const Icon(Icons.sports_martial_arts),
                    label: const Text('Jugar ronda'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reiniciar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
