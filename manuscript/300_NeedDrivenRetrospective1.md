# Test-driving at the input boundary - a retrospective

TODO: overdesign (and Sandro Mancuso version - compare with code and dependencies count, query count), anticorruption layer, mapping vs. wrapping. Wrapping is a little bit harder to maintain in case domain model follows the data, but is more convenient when domain model diverges from the data model.

```csharp
[Fact] public void
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
{
  //GIVEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var commandFactory = Substitute.For<CommandFactory>();
  var reservationInProgressFactory = Substitute<ReservationInProgressFactory>();
  var reservationInProgress = Substitute.For<ReservationInProgress>();
  var expectedReservationDto = Any.Instance<ReservationDto>();
  var reservationCommand = Substitute.For<ReservationCommand>();

  var ticketOffice = new TicketOffice(
    reservationInProgressFactory,
    commandFactory);

  reservationInProgressFactory.FreshInstance()
    .Returns(reservationInProgress);
  commandFactory.CreateReservationCommand(requestDto, reservationInProgress)
    .Returns(reservationCommand);
  reservationInProgress.ToDto()
    .Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservationDto, reservationDto);
  reservationCommand.Received(1).Execute();
}
```

```csharp
[Fact] public void
ShouldExecuteReservationCommandAndReturnResponseWhenMakingReservation()
{
  //GIVEN
  var requestDto = Any.Instance<ReservationRequestDto>();
  var expectedReservationDto = Any.Instance<ReservationDto>();

  var ticketOffice = new TicketOffice(
    facade);

  facade.MakeReservation(requestDto).Returns(expectedReservationDto);

  //WHEN
  var reservationDto = ticketOffice.MakeReservation(requestDto);

  //THEN
  Assert.Equal(expectedReservationDto, reservationDto);
}
```

No value unless we intend to catch some exceptions here. The next class has to handle the DTO.

TODO: other ways to test-drive this (higher level tests)
TODO: Design quality vs. Tests (intro) and what this example told us - verifying and setting up a mock for the same method is violation of the CQS principle, too many mocks - too many dependencies. Too many stubs - violation of TDA principle. These things *may* mean a violation.

Next chapter - a factory