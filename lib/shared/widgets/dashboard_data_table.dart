import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// 🌟 প্রতিটি ড্যাশবোর্ডের জন্য রিইউজেবল ডাটা টেবিল ও কার্ড কম্পোনেন্ট
class DashboardDataTable<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? headerAction;

  // Search & Filter
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final Widget? filterWidget;

  // Pagination
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int limit;
  final List<int> limitOptions;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onLimitChanged;

  // Data & State
  final List<T> items;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const DashboardDataTable({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.headerAction,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.filterWidget,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    this.limit = 10,
    this.limitOptions = const [10, 25, 50],
    this.onPageChanged,
    this.onLimitChanged,
    required this.items,
    required this.isLoading,
    this.emptyTitle = 'No data found',
    this.emptySubtitle = 'Assigned records will appear here.',
    required this.itemBuilder,
  });

  @override
  State<DashboardDataTable<T>> createState() => _DashboardDataTableState<T>();
}

class _DashboardDataTableState<T> extends State<DashboardDataTable<T>> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      widget.onSearchChanged?.call(value.trim());
    });
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section
        _buildHeader(),
        const SizedBox(height: 16),

        // 2. Control Bar (Search + Limit Selector)
        _buildControlBar(),
        const SizedBox(height: 16),

        // 3. Main Data Container (Skeleton / Empty / Cards)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E2D8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (widget.isLoading)
                _buildSkeletonLoader()
              else if (widget.items.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE7E2D8),
                  ),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return widget.itemBuilder(context, item, index);
                  },
                ),

              // 4. Pagination Footer
              if (!widget.isLoading && widget.items.isNotEmpty)
                _buildPaginationFooter(),
            ],
          ),
        ),
      ],
    );
  }

  // 🌟 Header
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(widget.icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2026),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B707E),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (widget.headerAction != null) widget.headerAction!,
      ],
    );
  }

  // 🌟 Control Bar
  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E2D8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E2D8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF9AA0AA),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E2026),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.searchHint,
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA0AA),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE7E2D8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Color(0xFF1E2026),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Limit Selector Dropdown
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7E2D8)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Show: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B707E)),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: widget.limit,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF1E2026),
                        ),
                        items: widget.limitOptions.map((opt) {
                          return DropdownMenuItem<int>(
                            value: opt,
                            child: Text(
                              '$opt',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2026),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newLimit) {
                          if (newLimit != null && newLimit != widget.limit) {
                            widget.onLimitChanged?.call(newLimit);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.filterWidget != null) ...[
            const SizedBox(height: 10),
            widget.filterWidget!,
          ],
        ],
      ),
    );
  }

  // 🌟 Loading Skeleton
  Widget _buildSkeletonLoader() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, index) =>
          const Divider(height: 1, color: Color(0xFFE7E2D8)),
      itemBuilder: (_, index) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEE6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EEE6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EEE6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEE6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🌟 Empty State
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFFBF3),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 28,
                color: Color(0xFF9AA0AA),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.emptyTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2026),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B707E)),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 Pagination Footer
  Widget _buildPaginationFooter() {
    final startItem = widget.totalItems > 0
        ? (widget.currentPage - 1) * widget.limit + 1
        : 0;
    final endItem = (widget.currentPage * widget.limit).clamp(
      0,
      widget.totalItems,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF3),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFE7E2D8))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startItem–$endItem of ${widget.totalItems}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B707E),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _PaginationButton(
                icon: Icons.chevron_left,
                label: 'Prev',
                enabled: widget.currentPage > 1,
                onTap: () => widget.onPageChanged?.call(widget.currentPage - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${widget.currentPage}/${widget.totalPages == 0 ? 1 : widget.totalPages}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2026),
                  ),
                ),
              ),
              _PaginationButton(
                icon: Icons.chevron_right,
                label: 'Next',
                enabled: widget.currentPage < widget.totalPages,
                onTap: () => widget.onPageChanged?.call(widget.currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🌟 Reusable Prev/Next Button
class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(0xFFE7E2D8)
                : const Color(0xFFE7E2D8).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (icon == Icons.chevron_left)
              Icon(
                icon,
                size: 14,
                color: enabled
                    ? const Color(0xFF1E2026)
                    : const Color(0xFF9AA0AA),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? const Color(0xFF1E2026)
                    : const Color(0xFF9AA0AA),
              ),
            ),
            if (icon == Icons.chevron_right)
              Icon(
                icon,
                size: 14,
                color: enabled
                    ? const Color(0xFF1E2026)
                    : const Color(0xFF9AA0AA),
              ),
          ],
        ),
      ),
    );
  }
}

/// 🌟 Reusable Status Badge Component
class DashboardStatusBadge extends StatelessWidget {
  final String status;

  const DashboardStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;

    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        bg = const Color(0xFFF0FDFA);
        text = const Color(0xFF0FA894);
        border = const Color(0xFFCCFBF1);
        break;
      case 'COMPLETED':
      case 'ACTIVE':
      case 'PAID':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF059669);
        border = const Color(0xFFA7F3D0);
        break;
      case 'DECLINED':
      case 'BLOCKED':
      case 'CANCELLED':
        bg = const Color(0xFFFFF1F2);
        text = const Color(0xFFE11D48);
        border = const Color(0xFFFECDD3);
        break;
      case 'PENDING':
      default:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFD97706);
        border = const Color(0xFFFDE68A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
