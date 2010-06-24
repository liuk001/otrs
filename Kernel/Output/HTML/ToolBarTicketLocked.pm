# --
# Kernel/Output/HTML/ToolBarTicketLocked.pm
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: ToolBarTicketLocked.pm,v 1.3 2010-06-24 12:15:26 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::ToolBarTicketLocked;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.3 $) [1];

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

    # get user lock data
    my $Count = $Self->{TicketObject}->TicketSearch(
        Result     => 'COUNT',
        Locks      => ['lock'],
        OwnerIDs   => [ $Self->{UserID} ],
        UserID     => 1,
        Permission => 'ro',
    );
    my $CountNew = $Self->{TicketObject}->TicketSearch(
        Result     => 'COUNT',
        Locks      => ['lock'],
        OwnerIDs   => [ $Self->{UserID} ],
        TicketFlag => {
            Seen => 1,
        },
        TicketFlagUserID => $Self->{UserID},
        UserID           => 1,
        Permission       => 'ro',
    );
    $CountNew = $Count - $CountNew;
    my $CountReached = $Self->{TicketObject}->TicketSearch(
        Result                        => 'COUNT',
        Locks                         => ['lock'],
        StateType                     => ['pending reminder'],
        TicketPendingTimeOlderMinutes => 1,
        OwnerIDs                      => [ $Self->{UserID} ],
        UserID                        => 1,
        Permission                    => 'ro',
    );

    my $Text    = $Self->{LayoutObject}->{LanguageObject}->Get('Locked Tickets Total');
    my $TextNew = $Self->{LayoutObject}->{LanguageObject}->Get('Locked Tickets New');
    my $TextReached
        = $Self->{LayoutObject}->{LanguageObject}->Get('Locked Tickets Reminder Reached');
    my $URL = $Self->{LayoutObject}->{Baselink};
    my %Return;
    $Return{'0999997'} = {
        Block       => 'ToolBarItem',
        Count       => $CountNew,
        Description => $TextNew,
        Class       => 'Stacks',

        #        Name        => $Text,
        #        Image       => 'personal.png',
        Link      => $URL . 'Action=AgentTicketLockedView;Filter=New',
        AccessKey => 'k',
    };
    $Return{'0999998'} = {
        Block       => 'ToolBarItem',
        Count       => $CountReached,
        Description => $TextReached,
        Class       => 'Stacks',

        #        Name        => $Text,
        #        Image       => 'personal.png',
        Link      => $URL . 'Action=AgentTicketLockedView;Filter=ReminderReached',
        AccessKey => 'k',
    };
    $Return{'0999999'} = {
        Block       => 'ToolBarItem',
        Count       => $Count,
        Description => $Text,
        Class       => 'Stacks',

        #        Name        => $Text,
        #        Image       => 'personal.png',
        Link      => $URL . 'Action=AgentTicketLockedView',
        AccessKey => 'k',
    };
    return %Return;
}

1;
