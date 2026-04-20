import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/coding_question_model.dart';
import '../providers/code_practice_provider.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CodePracticeProvider>();
      if (provider.questions.isEmpty) {
        provider.loadQuestions();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _inputController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadStarterCode(CodingQuestionModel question) {
    _codeController.text = question.starterCode;
    _inputController.text = question.sampleInput;
  }

  void _onQuestionSelected(CodingQuestionModel question) {
    final provider = context.read<CodePracticeProvider>();
    provider.selectQuestion(question);
    _loadStarterCode(question);
    provider.loadSubmissionHistory(questionId: question.id);
    _tabController.index = 0;
  }

  void _runCode() {
    final provider = context.read<CodePracticeProvider>();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write some code first.')),
      );
      return;
    }
    final customInput = _inputController.text;
    provider.runCode(code, customInput: customInput);
    _tabController.index = 1;
  }

  void _submitCode() {
    final provider = context.read<CodePracticeProvider>();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write some code first.')),
      );
      return;
    }
    provider.submitCode(code);
    _tabController.index = 1;
  }

  void _resetCode() {
    final provider = context.read<CodePracticeProvider>();
    if (provider.selectedQuestion != null) {
      _loadStarterCode(provider.selectedQuestion!);
      provider.clearResults();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to starter code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CodePracticeProvider>(
      builder: (context, provider, _) {
        if (!_initialized && provider.selectedQuestion != null) {
          _initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadStarterCode(provider.selectedQuestion!);
            provider.loadSubmissionHistory(
              questionId: provider.selectedQuestion!.id,
            );
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E2E),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Code Practice',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            actions: [
              if (provider.selectedQuestion != null)
                IconButton(
                  onPressed: _resetCode,
                  icon: const Icon(Icons.restart_alt_rounded, size: 22),
                  tooltip: 'Reset Code',
                ),
            ],
          ),
          body: provider.isLoadingQuestions
              ? const Center(child: CircularProgressIndicator())
              : provider.questions.isEmpty
                  ? _buildEmptyState(provider)
                  : _buildMainContent(provider),
        );
      },
    );
  }

  Widget _buildEmptyState(CodePracticeProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code_off_rounded, size: 56, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'No questions available.',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadQuestions(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(CodePracticeProvider provider) {
    return Column(
      children: [
        _QuestionSelector(
          questions: provider.questions,
          selected: provider.selectedQuestion,
          onSelect: _onQuestionSelected,
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                color: const Color(0xFF1E1E2E),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF60A5FA),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF9CA3AF),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Problem'),
                    Tab(text: 'Output'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProblemTab(
                      question: provider.selectedQuestion,
                      codeController: _codeController,
                      inputController: _inputController,
                      isRunning: provider.isRunningCode,
                      isSubmitting: provider.isSubmittingCode,
                      onRun: _runCode,
                      onSubmit: _submitCode,
                    ),
                    _OutputTab(provider: provider),
                    _HistoryTab(history: provider.submissionHistory),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _QuestionSelector extends StatelessWidget {
  final List<CodingQuestionModel> questions;
  final CodingQuestionModel? selected;
  final ValueChanged<CodingQuestionModel> onSelect;

  const _QuestionSelector({
    required this.questions,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFF282A36),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final q = questions[index];
          final isSelected = selected?.id == q.id;
          return GestureDetector(
            onTap: () => onSelect(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF3B3D4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFCDD6F4),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _ProblemTab extends StatelessWidget {
  final CodingQuestionModel? question;
  final TextEditingController codeController;
  final TextEditingController inputController;
  final bool isRunning;
  final bool isSubmitting;
  final VoidCallback onRun;
  final VoidCallback onSubmit;

  const _ProblemTab({
    required this.question,
    required this.codeController,
    required this.inputController,
    required this.isRunning,
    required this.isSubmitting,
    required this.onRun,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (question == null) {
      return const Center(
        child: Text('Select a question above.',
            style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // title
        Text(
          question!.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            question!.difficulty.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF16A34A),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // problem statement
        _InfoCard(
          title: 'Problem',
          child: Text(
            question!.problemStatement,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151)),
          ),
        ),

        if (question!.inputDescription.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoCard(
            title: 'Input',
            child: Text(
              question!.inputDescription,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        ],

        if (question!.sampleInput.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SampleCard(
            label: 'Sample Input',
            value: question!.sampleInput,
          ),
        ],

        const SizedBox(height: 10),
        _SampleCard(
          label: 'Expected Output',
          value: question!.expectedOutput,
        ),

        const SizedBox(height: 18),

        // code editor
        const Text(
          'Your Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B3D4A)),
          ),
          child: TextField(
            controller: codeController,
            maxLines: 14,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFCDD6F4),
              height: 1.5,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(14),
              border: InputBorder.none,
              hintText: '# write your code here...',
              hintStyle: TextStyle(
                color: Color(0xFF6B7280),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
        ),

        const SizedBox(height: 14),

        // custom input
        const Text(
          'Custom Input (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: inputController,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: 'Enter test input...',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isRunning || isSubmitting ? null : onRun,
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(isRunning ? 'Running...' : 'Run Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isRunning || isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(isSubmitting ? 'Judging...' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}


class _OutputTab extends StatelessWidget {
  final CodePracticeProvider provider;

  const _OutputTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final run = provider.lastRunResult;
    final sub = provider.lastSubmissionResult;

    if (run == null && sub == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_rounded, size: 48, color: Color(0xFFD1D5DB)),
            SizedBox(height: 10),
            Text(
              'Run or submit code to see output.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sub != null) ...[
          _VerdictBanner(passed: sub.passed, timedOut: sub.timedOut),
          const SizedBox(height: 14),
          if (sub.errorMessage != null && !sub.passed) ...[
            _ErrorMessageBanner(message: sub.errorMessage!),
            const SizedBox(height: 10),
          ],
          _OutputBlock(label: 'Your Output', text: sub.actualOutput),
          const SizedBox(height: 10),
          _OutputBlock(label: 'Expected Output', text: sub.expectedOutput),
          if (sub.stderrOutput.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ErrorBlock(text: sub.stderrOutput),
          ],
          const SizedBox(height: 8),
          Text(
            'Execution: ${sub.executionTimeMs} ms',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ] else if (run != null) ...[
          if (run.timedOut)
            _VerdictBanner(passed: false, timedOut: true)
          else if (!run.success)
            _VerdictBanner(passed: false, timedOut: false),
          if (run.timedOut || !run.success) const SizedBox(height: 14),
          _OutputBlock(label: 'Standard Output', text: run.stdout),
          if (run.stderr.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ErrorBlock(text: run.stderr),
          ],
          const SizedBox(height: 8),
          Text(
            'Execution: ${run.executionTimeMs} ms',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ],
    );
  }
}



class _HistoryTab extends StatelessWidget {
  final List<dynamic> history;

  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: Color(0xFFD1D5DB)),
            SizedBox(height: 10),
            Text(
              'No submissions yet.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = history[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.passed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.passed
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  size: 18,
                  color: item.passed
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.questionTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.executionTimeMs} ms',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.passed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.passed ? 'PASSED' : 'FAILED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.passed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _ErrorMessageBanner extends StatelessWidget {
  final String message;

  const _ErrorMessageBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFF97316)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _VerdictBanner extends StatelessWidget {
  final bool passed;
  final bool timedOut;

  const _VerdictBanner({required this.passed, required this.timedOut});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (timedOut) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFF59E0B);
      icon = Icons.timer_off_rounded;
      label = 'Time Limit Exceeded';
    } else if (passed) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      icon = Icons.check_circle_rounded;
      label = 'Accepted';
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
      label = 'Wrong Answer';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}


class _OutputBlock extends StatelessWidget {
  final String label;
  final String text;

  const _OutputBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            text.isEmpty ? '(no output)' : text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFFCDD6F4),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}


class _ErrorBlock extends StatelessWidget {
  final String text;

  const _ErrorBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Error Output',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1B1B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7F1D1D)),
          ),
          child: SelectableText(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFFCA5A5),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}


class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}


class _SampleCard extends StatelessWidget {
  final String label;
  final String value;

  const _SampleCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded,
                    size: 16, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
