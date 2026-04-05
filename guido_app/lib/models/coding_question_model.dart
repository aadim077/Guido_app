class CodingQuestionModel {
  final int id;
  final String title;
  final String slug;
  final String problemStatement;
  final String inputDescription;
  final String sampleInput;
  final String expectedOutput;
  final String starterCode;
  final String difficulty;
  final int order;

  CodingQuestionModel({
    required this.id,
    required this.title,
    required this.slug,
    this.problemStatement = '',
    this.inputDescription = '',
    this.sampleInput = '',
    this.expectedOutput = '',
    this.starterCode = '',
    this.difficulty = 'beginner',
    this.order = 1,
  });

  factory CodingQuestionModel.fromJson(Map<String, dynamic> json) {
    return CodingQuestionModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      problemStatement: json['problem_statement'] as String? ?? '',
      inputDescription: json['input_description'] as String? ?? '',
      sampleInput: json['sample_input'] as String? ?? '',
      expectedOutput: json['expected_output'] as String? ?? '',
      starterCode: json['starter_code'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      order: json['order'] as int? ?? 1,
    );
  }
}
