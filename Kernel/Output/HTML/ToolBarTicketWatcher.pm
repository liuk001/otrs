# --
# Kernel/Output/HTML/ToolBarTicketWatcher.pm
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: ToolBarTicketWatcher.pm,v 1.4 2010-06-24 12:15:26 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ToolBarTicketWatcher;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.4 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for (qw(ConfigObject LogObject DBObject TicketObject LayoutObject UserID)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check if feature is aktive
    return if !$Self->{ConfigObject}->Get('Ticket::Watcher');

    # check access
    my @Groups;
    if ( $Self->{ConfigObject}->Get('Ticket::WatcherGroup') ) {
        @Groups = @{ $Self->{ConfigObject}->Get('Ticket::WatcherGroup') };
    }
    if (@Groups) {
        my $Access = 0;
        for my $Group (@Groups) {
            next if !$Self->{LayoutObject}->{"UserIsGroup[$Group]"};
            if ( $Self->{LayoutObject}->{"UserIsGroup[$Group]"} eq 'Yes' ) {
                $Access = 1;
                last;
            }
        }

        # return on no access
        return if !$Access;
    }

    # find watched tickets
    my $Count = $Self->{TicketObject}->TicketSearch(
        Result       => 'COUNT',
        WatchUserIDs => [ $Self->{UserID} ],
        UserID       => 1,
        Permission   => 'ro',
    );
    my $CountNew = $Self->{TicketObject}->TicketSearch(
        Result       => 'COUNT',
        WatchUserIDs => [ $Self->{UserID} ],
        TicketFlag   => {
            Seen => 1,
        },
        TicketFlagUserID => $Self->{UserID},
        UserID           => 1,
        Permission       => 'ro',
    );
    $CountNew = $Count - $CountNew;

    my $CountReached = $Self->{TicketObject}->TicketSearch(
        Result                        => 'COUNT',
        StateType                     => ['pending reminder'],
        WatchUserIDs                  => [ $Self->{UserID} ],
        TicketPendingTimeOlderMinutes => 1,
        UserID                        => 1,
        Permission                    => 'ro',
    );

    my $Text        = $Self->{LayoutObject}->{LanguageObject}->Get('Watched Total');
    my $TextNew     = $Self->{LayoutObject}->{LanguageObject}->Get('Watched New');
    my $TextReached = $Self->{LayoutObject}->{LanguageObject}->Get('Watched Reminder Reached');

    my $URL = $Self->{LayoutObject}->{Baselink};
    my %Return;
    $Return{'0999977'} = {
        Block       => 'ToolBarItem',
        Description => $TextNew,
        Count       => $CountNew,
        Class       => 'Alerts',

        #        Name        => $Text,
        #        Image       => 'watcher.png',
        Link      => $URL . 'Action=AgentTicketWatchView;Filter=New',
        AccessKey => '',
    };
    $Return{'0999978'} = {
        Block       => 'ToolBarItem',
        Description => $TextReached,
        Count       => $CountReached,
        Class       => 'Alerts',

        #        Name        => $Text,
        #        Image       => 'watcher.png',
        Link      => $URL . 'Action=AgentTicketWatchView;Filter=ReminderReached',
        AccessKey => '',
    };
    $Return{'0999979'} = {
        Block       => 'ToolBarItem',
        Description => $Text,
        Count       => $Count,
        Class       => 'Alerts',

        #        Name        => $Text,
        #        Image       => 'watcher.png',
        Link      => $URL . 'Action=AgentTicketWatchView',
        AccessKey => '',
    };
    return %Return;
}

1;
