/// The day's quote and the day's joke.
///
/// Bundled, not fetched: the spec says the app works fully offline except for
/// LLM calls, and a motivational line that needs a network is a bad joke on
/// its own. Selection is deterministic per calendar day, so it stays put all
/// day and changes at midnight.
///
/// Editorial rule for the jokes: the target is always a habit, a gadget, or
/// wellness culture — never the user's body, weight, appetite, or what they
/// ate. A health app that mocks its user is a health app people delete.
library;

class DailySpark {
  const DailySpark({
    required this.quote,
    required this.attribution,
    required this.joke,
  });

  final String quote;

  /// Null for lines written for PulsIQ rather than borrowed.
  final String? attribution;
  final String joke;
}

/// Prime-length lists so a quote and a joke don't pair up the same way twice
/// for years.
const _quotes = <(String, String?)>[
  ('The greatest wealth is health.', 'Virgil'),
  ('A journey of a thousand miles begins with a single step.', 'Lao Tzu'),
  (
    'It is not that we have a short time to live, but that we waste much of it.',
    'Seneca'
  ),
  ('Fall seven times, stand up eight.', 'Japanese proverb'),
  (
    'You have power over your mind — not outside events. Realize this, and '
        'you will find strength.',
    'Marcus Aurelius'
  ),
  (
    'We are what we repeatedly do. Excellence, then, is not an act but a habit.',
    'Will Durant'
  ),
  ('He who has health has hope, and he who has hope has everything.',
      'Arabian proverb'),
  ('Take care of your body. It is the only place you have to live.', null),
  ('The body achieves what the mind believes.', null),
  ('Small steps, taken daily, outrun big plans made yearly.', null),
  ('Rest is not the opposite of progress. It is part of it.', null),
  ('You do not need a perfect week. You need a repeatable one.', null),
  ('Energy is not something you find. It is something you build.', null),
  ('The best workout is the one you actually come back to tomorrow.', null),
  ('Hydration is the cheapest upgrade you will ever make.', null),
  ('Consistency beats intensity, and it is not close.', null),
  ('Your future self is watching you right now through memories.', null),
  ('Sleep is the foundation. Everything else is decoration.', null),
  ('Progress is rarely loud. Mostly it just shows up again.', null),
  ('Do not trade what you want most for what you want right now.', null),
  ('Strength is a skill. Skills are practiced, not wished for.', null),
  ('A body in motion tends to stay optimistic.', null),
  ('You are allowed to start again at any hour of any day.', null),
  ('Discipline is choosing between what you want now and what you want more.',
      null),
  ('Nothing changes if nothing changes — but very little needs to.', null),
  ('The plate you build today writes the energy you spend tomorrow.', null),
  ('Motivation gets you started. Systems keep you going.', null),
  ('Slow progress is still the fastest route that actually works.', null),
  ('Health is not a destination you arrive at. It is a direction you face.',
      null),
];

const _jokes = <String>[
  'Your step counter says you walked 12,000 steps. Eight thousand of those '
      'were looking for your phone.',
  'Meal prep: the ancient art of getting sick of Tuesday\'s lunch on Sunday.',
  'You bought a gallon water bottle. It is now a very expensive desk '
      'ornament with motivational time markers you ignore hourly.',
  'Your smartwatch congratulated you for standing. The bar is on the floor, '
      'and you still had to be reminded to step over it.',
  'Nothing humbles a person like a fitness app cheerfully asking how that '
      '"rest week" is going. It has been five weeks. It knows.',
  'The gym at 6am is full of people who will tell you about it at 9am.',
  'Wellness influencers have discovered a revolutionary secret: vegetables. '
      'Available since roughly forever, at a store near you.',
  'Your sleep tracker gave you a score of 62 and no way to appeal.',
  'Somewhere a protein bar is being marketed as a dessert and a dessert is '
      'being marketed as a protein bar. Both are candy.',
  'You did not forget leg day. You simply scheduled it for a date that does '
      'not exist.',
  '"I\'ll start Monday" is the most popular fitness plan in human history '
      'and it has a zero percent completion rate.',
  'Your fridge has a drawer specifically designed to make vegetables '
      'invisible until they are compost.',
  'The treadmill has 47 workout programs. You have used the one that starts '
      'it and the one that stops it.',
  'Detox tea is just tea that costs more and is ruder to your afternoon.',
  'Every fitness app eventually becomes a diary of your good intentions, '
      'timestamped and searchable.',
  'You know the water is healthy because it costs four dollars and tastes '
      'like a rumor.',
  'Standing desks: now you can be tired in an entirely new posture.',
  'Your running shoes have logged more miles in the hallway than outdoors.',
  'The hardest part of any workout is the twenty minutes of looking for '
      'headphones beforehand.',
  'Superfood is a marketing term. Blueberries are simply berries with an '
      'agent.',
  'Your smart scale syncs to three apps so that bad news can arrive '
      'simultaneously on every device you own.',
  'Nobody has ever finished a yoga class and said "that was easy" without '
      'lying to at least one person in the room.',
  'The step counter counted your commute as exercise. Let it. It is trying '
      'its best.',
  'Sports drinks are for athletes. You are on the couch. You are, at best, '
      'sports adjacent.',
  'Every January, gyms sell hope by the month and collect on it by March.',
  'Your fitness tracker buzzed to say you have been inactive. So has it. It '
      'is on your wrist.',
  'Air fryers did not change your diet. They changed the appliance that '
      'makes the same food.',
  'The recipe said "serves four." It served one, and that one has no '
      'regrets and no leftovers.',
  'A smoothie is a salad that gave up on being chewed.',
  'You have twelve unread notifications from apps that want you to be a '
      'better person. They can wait until after lunch.',
  'Somebody is out there doing burpees voluntarily right now, and that is '
      'their business, not a moral standard.',
];

final _epoch = DateTime.utc(2024, 1, 1);

int _dayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).difference(_epoch).inDays;

/// The spark for [day] — stable for the whole calendar day.
DailySpark sparkFor(DateTime day) {
  final n = _dayNumber(day);
  // Modulo of a negative day number would throw off the index; Dart's % on
  // ints is already non-negative for a positive divisor, so this is safe
  // even for dates before the epoch.
  final (quote, attribution) = _quotes[n % _quotes.length];
  return DailySpark(
    quote: quote,
    attribution: attribution,
    joke: _jokes[n % _jokes.length],
  );
}
