const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const interestCategories = [
  {
    name: 'Sports & Fitness',
    icon: '⚽',
    interests: [
      'Running', 'Cycling', 'Swimming', 'Hiking', 'Yoga', 'Gym & Weights',
      'Tennis', 'Basketball', 'Football', 'Cricket', 'Surfing', 'Martial Arts',
      'Rock Climbing', 'Dancing', 'Pilates',
    ],
  },
  {
    name: 'Arts & Creativity',
    icon: '🎨',
    interests: [
      'Painting', 'Drawing', 'Photography', 'Writing', 'Pottery', 'Sculpture',
      'Graphic Design', 'Film Making', 'Knitting & Crochet', 'Woodworking',
      'Calligraphy', 'Digital Art', 'Jewellery Making',
    ],
  },
  {
    name: 'Music',
    icon: '🎵',
    interests: [
      'Playing Guitar', 'Playing Piano', 'Singing', 'DJing', 'Music Production',
      'Concert Going', 'Jazz', 'Classical Music', 'Rock & Indie', 'Electronic Music',
      'Hip Hop', 'Folk & Acoustic', 'Drumming',
    ],
  },
  {
    name: 'Food & Drink',
    icon: '🍳',
    interests: [
      'Cooking', 'Baking', 'Wine Tasting', 'Craft Beer', 'Coffee', 'BBQ & Grilling',
      'Vegetarian & Vegan Cooking', 'Asian Cuisine', 'Italian Cuisine',
      'Food Markets', 'Restaurant Exploring', 'Fermentation',
    ],
  },
  {
    name: 'Outdoors & Nature',
    icon: '🌿',
    interests: [
      'Bushwalking', 'Camping', 'Fishing', 'Bird Watching', 'Gardening',
      'Kayaking', 'Sailing', 'Scuba Diving', 'Stargazing', 'Beach Going',
      'National Parks', 'Conservation', 'Mountain Biking',
    ],
  },
  {
    name: 'Technology',
    icon: '💻',
    interests: [
      'Programming', 'AI & Machine Learning', 'Gaming', 'VR & AR',
      'Robotics', 'Cybersecurity', 'Web Development', 'Data Science',
      'Home Automation', '3D Printing', 'Drones', 'Open Source',
    ],
  },
  {
    name: 'Learning & Ideas',
    icon: '📚',
    interests: [
      'Book Club', 'Philosophy', 'History', 'Science', 'Language Learning',
      'Psychology', 'Podcasts', 'Documentaries', 'TED Talks', 'Astronomy',
      'Economics', 'Trivia & Quiz Nights',
    ],
  },
  {
    name: 'Social & Community',
    icon: '🤝',
    interests: [
      'Volunteering', 'Mentoring', 'Networking', 'Community Organising',
      'Public Speaking', 'Debate', 'Charity Work', 'Environmental Activism',
      'Cultural Events', 'Board Games', 'Card Games',
    ],
  },
  {
    name: 'Travel & Adventure',
    icon: '✈️',
    interests: [
      'Backpacking', 'Road Trips', 'Solo Travel', 'Cultural Tourism',
      'Adventure Sports', 'City Exploring', 'Budget Travel', 'Photography Tours',
      'Digital Nomad Life', 'Festivals', 'Heritage Sites',
    ],
  },
  {
    name: 'Wellness & Mindfulness',
    icon: '🧘',
    interests: [
      'Meditation', 'Mindfulness', 'Journaling', 'Breathwork', 'Tai Chi',
      'Mental Health Advocacy', 'Healthy Living', 'Self Development',
      'Gratitude Practice', 'Digital Detox', 'Nature Therapy',
    ],
  },
];

async function seed() {
  console.log('🌱 Seeding interest categories and tags...\n');

  let totalInterests = 0;

  for (let i = 0; i < interestCategories.length; i++) {
    const cat = interestCategories[i];

    // Upsert category
    const category = await prisma.interestCategory.upsert({
      where: { name: cat.name },
      update: { icon: cat.icon, sortOrder: i },
      create: { name: cat.name, icon: cat.icon, sortOrder: i },
    });

    console.log(`  ${cat.icon} ${cat.name} (${cat.interests.length} interests)`);

    // Upsert interests
    for (let j = 0; j < cat.interests.length; j++) {
      await prisma.interest.upsert({
        where: { name: cat.interests[j] },
        update: { categoryId: category.id, sortOrder: j },
        create: {
          name: cat.interests[j],
          categoryId: category.id,
          sortOrder: j,
        },
      });
      totalInterests++;
    }
  }

  console.log(`\n✅ Seeded ${interestCategories.length} categories, ${totalInterests} interests`);
}

seed()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
