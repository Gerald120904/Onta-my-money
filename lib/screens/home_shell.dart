import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';

import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'reports_screen.dart' as reports;
import 'review_screen.dart' as review;
import 'transactions_screen.dart';

class HomeShell extends StatefulWidget {
  final AppState state;

  const HomeShell({
    super.key,
    required this.state,
  });

  @override
  State<HomeShell> createState() =>
      _HomeShellState();
}

class _HomeShellState
    extends State<HomeShell> {
  int index = 0;

  // =========================================================
  // ABRIR NUEVO REPORTE
  // =========================================================

  void goReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (
          reviewContext,
        ) {
          return review.ReviewScreen(
            state:
                widget.state,

            onCompleted: (
              result,
            ) {
              widget.state
                  .saveReviewResult(
                result,
              );

              if (!mounted) {
                return;
              }

              setState(() {
                index = 2;
              });
            },

            onExit: () {
              Navigator.of(
                reviewContext,
              ).pop();
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // CAMBIAR PESTAÑA
  // =========================================================

  void changePage(
    int value,
  ) {
    setState(() {
      index = value;
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final pages = [
      DashboardScreen(
        state:
            widget.state,
        onReview:
            goReview,
      ),

      TransactionsScreen(
        state:
            widget.state,
      ),

      reports.ReportsScreen(
        state:
            widget.state,
        onCreateReview:
            goReview,
      ),

      MoreScreen(
        state:
            widget.state,
      ),
    ];

    const destinations = [
      NavigationDestination(
        icon:
            Icon(
          Icons.home_outlined,
        ),
        selectedIcon:
            Icon(
          Icons.home_rounded,
        ),
        label:
            'Inicio',
      ),

      NavigationDestination(
        icon:
            Icon(
          Icons
              .receipt_long_outlined,
        ),
        selectedIcon:
            Icon(
          Icons
              .receipt_long_rounded,
        ),
        label:
            'Movimientos',
      ),

      NavigationDestination(
        icon:
            Icon(
          Icons
              .insert_chart_outlined,
        ),
        selectedIcon:
            Icon(
          Icons
              .insert_chart_rounded,
        ),
        label:
            'Reportes',
      ),

      NavigationDestination(
        icon:
            Icon(
          Icons
              .more_horiz_rounded,
        ),
        selectedIcon:
            Icon(
          Icons
              .more_horiz_rounded,
        ),
        label:
            'Más',
      ),
    ];

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final desktop =
            constraints.maxWidth >=
                900;

        double maxWidth;

        switch (index) {
          case 1:
            maxWidth = 1000;
            break;

          case 2:
            maxWidth = 900;
            break;

          default:
            maxWidth = 470;
        }

        final content =
            SafeArea(
          child: Align(
            alignment:
                Alignment.topCenter,
            child:
                ConstrainedBox(
              constraints:
                  BoxConstraints(
                maxWidth:
                    maxWidth,
              ),
              child:
                  pages[index],
            ),
          ),
        );

        if (!desktop) {
          return Scaffold(
            backgroundColor:
                AppTheme.background,
            body:
                content,
            bottomNavigationBar:
                NavigationBar(
              selectedIndex:
                  index,
              onDestinationSelected:
                  changePage,
              destinations:
                  destinations,
            ),
          );
        }

        return Scaffold(
          backgroundColor:
              AppTheme.background,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex:
                    index,
                labelType:
                    NavigationRailLabelType
                        .all,
                onDestinationSelected:
                    changePage,
                leading:
                    const Padding(
                  padding:
                      EdgeInsets
                          .symmetric(
                    vertical:
                        22,
                  ),
                  child:
                      CircleAvatar(
                    radius:
                        25,
                    backgroundColor:
                        AppTheme
                            .primaryDark,
                    child:
                        Icon(
                      Icons
                          .account_balance_wallet_rounded,
                      color:
                          Colors
                              .white,
                    ),
                  ),
                ),
                destinations:
                    destinations
                        .map(
                          (
                            destination,
                          ) {
                            return NavigationRailDestination(
                              icon:
                                  destination
                                      .icon,
                              selectedIcon:
                                  destination
                                      .selectedIcon,
                              label:
                                  Text(
                                destination
                                    .label,
                              ),
                            );
                          },
                        )
                        .toList(),
              ),

              const VerticalDivider(
                width: 1,
              ),

              Expanded(
                child:
                    content,
              ),
            ],
          ),
        );
      },
    );
  }
}