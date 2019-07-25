!**********************************************************************************************************************************
!> ## FASTWrapper
!! The FASTWrapper and FASTWrapper_Types modules make up a template for creating user-defined calculations in the FAST Modularization
!! Framework. FASTWrappers_Types will be auto-generated by the FAST registry program, based on the variables specified in the
!! FASTWrapper_Registry.txt file.
!!
! ..................................................................................................................................
!! ## LICENSING
!! Copyright (C) 2012-2013, 2015-2016  National Renewable Energy Laboratory
!!
!!    This file is part of FASTWrapper.
!!
!! Licensed under the Apache License, Version 2.0 (the "License");
!! you may not use this file except in compliance with the License.
!! You may obtain a copy of the License at
!!
!!     http://www.apache.org/licenses/LICENSE-2.0
!!
!! Unless required by applicable law or agreed to in writing, software
!! distributed under the License is distributed on an "AS IS" BASIS,
!! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!! See the License for the specific language governing permissions and
!! limitations under the License.
!**********************************************************************************************************************************
MODULE FASTWrapper

   USE FASTWrapper_Types
   USE NWTC_Library
   USE FAST_Subs


   IMPLICIT NONE

   PRIVATE

   TYPE(ProgDesc), PARAMETER  :: FWrap_Ver = ProgDesc( 'FASTWrapper', 'v1.00.00', '7-Feb-2017' ) !< module date/version information

   REAL(DbKi),  PARAMETER  :: t_initial = 0.0_DbKi                    ! Initial time

   ! ..... Public Subroutines ...................................................................................................

   PUBLIC :: FWrap_Init                           !  Initialization routine
   PUBLIC :: FWrap_End                            !  Ending routine (includes clean up)

   PUBLIC :: FWrap_t0                             !  call to compute outputs at t0 [and initialize some more variables]
   PUBLIC :: FWrap_Increment                      !  call to update states to n+1 and compute outputs at n+1
   

CONTAINS
!----------------------------------------------------------------------------------------------------------------------------------
!> This routine is called at the start of the simulation to perform initialization steps.
!! The parameters are set here and not changed during the simulation.
!! The initial states and initial guess for the input are defined.   
SUBROUTINE FWrap_Init( InitInp, u, p, x, xd, z, OtherState, y, m, Interval, InitOut, ErrStat, ErrMsg )
!..................................................................................................................................

   TYPE(FWrap_InitInputType),       INTENT(IN   )  :: InitInp     !< Input data for initialization routine
   TYPE(FWrap_InputType),           INTENT(  OUT)  :: u           !< An initial guess for the input; input mesh must be defined
   TYPE(FWrap_ParameterType),       INTENT(  OUT)  :: p           !< Parameters
   TYPE(FWrap_ContinuousStateType), INTENT(  OUT)  :: x           !< Initial continuous states
   TYPE(FWrap_DiscreteStateType),   INTENT(  OUT)  :: xd          !< Initial discrete states
   TYPE(FWrap_ConstraintStateType), INTENT(  OUT)  :: z           !< Initial guess of the constraint states
   TYPE(FWrap_OtherStateType),      INTENT(  OUT)  :: OtherState  !< Initial other states (logical, etc)
   TYPE(FWrap_OutputType),          INTENT(  OUT)  :: y           !< Initial system outputs (outputs are not calculated;
                                                                  !!   only the output mesh is initialized)
   TYPE(FWrap_MiscVarType),         INTENT(  OUT)  :: m           !< Misc variables for optimization (not copied in glue code)
   REAL(DbKi),                      INTENT(IN   )  :: Interval    !< Coupling interval in seconds: the rate that
                                                                  !!   (1) Wrap_UpdateStates() is called in loose coupling &
                                                                  !!   (2) Wrap_UpdateDiscState() is called in tight coupling.
                                                                  !!   Input is the suggested time from the glue code;
                                                                  !!   Output is the actual coupling interval that will be used
                                                                  !!   by the glue code.
   TYPE(FWrap_InitOutputType),      INTENT(  OUT)  :: InitOut     !< Output for initialization routine
   INTEGER(IntKi),                  INTENT(  OUT)  :: ErrStat     !< Error status of the operation
   CHARACTER(*),                    INTENT(  OUT)  :: ErrMsg      !< Error message if ErrStat /= ErrID_None

      ! local variables
   TYPE(FAST_ExternInitType)                       :: ExternInitData 
   INTEGER(IntKi)                                  :: j,k,nb      
   
   INTEGER(IntKi)                                  :: ErrStat2    ! local error status
   CHARACTER(ErrMsgLen)                            :: ErrMsg2     ! local error message
   CHARACTER(*), PARAMETER                         :: RoutineName = 'FWrap_Init'

   
      ! Initialize variables

   ErrStat = ErrID_None
   ErrMsg  = ''


      ! Initialize the NWTC Subroutine Library

   !call NWTC_Init( )
   
      ! Display the module information

   if (InitInp%TurbNum == 1) call DispNVD( FWrap_Ver )
   InitOut%Ver = FWrap_Ver


      ! Define initial system states here:

   x%Dummy          = 0.0_ReKi
   xd%Dummy         = 0.0_ReKi
   z%Dummy          = 0.0_ReKi
   OtherState%Dummy = 0.0_ReKi


      ! Define initial guess for the system inputs here:

   
      !.................
      ! Initialize an instance of FAST
      !................
   
         !.... Lidar data (unused) ....
      ExternInitData%Tmax = InitInp%TMax
      ExternInitData%SensorType = SensorType_None
      ExternInitData%LidRadialVel = .false.
      
         !.... supercontroller ....
      if ( InitInp%UseSC ) then
         ExternInitData%NumSC2Ctrl     = InitInp%NumSC2Ctrl     ! "number of controller inputs [from supercontroller]"
         ExternInitData%NumCtrl2SC     = InitInp%NumCtrl2SC     ! "number of controller outputs [to supercontroller]"
         ExternInitData%NumSC2CtrlGlob = InitInp%NumSC2CtrlGlob ! "number of global controller inputs [from supercontroller]"
         call AllocAry(ExternInitData%fromSCGlob, InitInp%NumSC2CtrlGlob, 'ExternInitData%InitScOutputsGlob (global inputs to turbine controller from supercontroller)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
         call AllocAry(ExternInitData%fromSC, InitInp%NumSC2Ctrl, ' ExternInitData%InitScOutputsTurbine (turbine-related inputs for turbine controller from supercontroller)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
         ExternInitData%fromSCGlob = InitInp%fromSCGlob
         ExternInitData%fromSC =  InitInp%fromSC
         call AllocAry(u%fromSCglob, InitInp%NumSC2CtrlGlob, 'u%fromSCglob (global inputs to turbine controller from supercontroller)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
         call AllocAry(u%fromSC, InitInp%NumSC2Ctrl, 'u%fromSC (turbine-related inputs for turbine controller from supercontroller)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
      else
         
         ExternInitData%NumSC2Ctrl     = 0 ! "number of controller inputs [from supercontroller]"
         ExternInitData%NumCtrl2SC     = 0 ! "number of controller outputs [to supercontroller]"
         ExternInitData%NumSC2CtrlGlob = 0 ! "number of global controller inputs [from supercontroller]"
      
      end if
         !.... multi-turbine options ....
      ExternInitData%TurbineID = InitInp%TurbNum
      ExternInitData%TurbinePos = InitInp%p_ref_Turbine
      
      ExternInitData%FarmIntegration = .true.
      ExternInitData%RootName = InitInp%RootName
            
         !.... 4D-wind data ....
      ExternInitData%windGrid_n(1) = InitInp%nX_high
      ExternInitData%windGrid_n(2) = InitInp%nY_high
      ExternInitData%windGrid_n(3) = InitInp%nZ_high
      ExternInitData%windGrid_n(4) = InitInp%n_high_low
      
      ExternInitData%windGrid_delta(1) = InitInp%dX_high
      ExternInitData%windGrid_delta(2) = InitInp%dY_high
      ExternInitData%windGrid_delta(3) = InitInp%dZ_high
      ExternInitData%windGrid_delta(4) = InitInp%dt_high
      
      ExternInitData%windGrid_pZero = InitInp%p_ref_high - InitInp%p_ref_Turbine
            
      
      CALL FAST_InitializeAll_T( t_initial, InitInp%TurbNum, m%Turbine, ErrStat2, ErrMsg2, InitInp%FASTInFile, ExternInitData ) 
         call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName) 
         if (ErrStat >= AbortErrLev) then
            call cleanup()
            return
         end if
         
      
      !.................
      ! Check that we've set up FAST properly:
      !.................
      if (m%Turbine%p_FAST%CompAero /= MODULE_AD) then
         call SetErrStat(ErrID_Fatal,"AeroDyn (v15) must be used in each instance of FAST for FAST.Farm.",ErrStat,ErrMsg,RoutineName)
         call cleanup()
         return
      end if
      
         ! move the misc var to the input variable...
      if (m%Turbine%p_FAST%CompInflow /= MODULE_IfW) then
         call SetErrStat(ErrID_Fatal,"InflowWind must be used in each instance of FAST for FAST.Farm.",ErrStat,ErrMsg,RoutineName)
         call cleanup()
         return
      end if
      
      call move_alloc(m%Turbine%IfW%m%FDext%V, u%Vdist_High)
         
      
      !.................
      ! Define parameters here:
      !.................

      call SetParameters(InitInp, p, m%Turbine%p_FAST%dt, Interval, ErrStat2, ErrMsg2)
         call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName) 
         if (ErrStat >= AbortErrLev) then
            call cleanup()
            return
         end if
         
      !.................
      ! Set outputs (allocate arrays and set miscVar meshes for computing other outputs):
      !.................
         
      call AllocAry(y%AzimAvg_Ct, p%nr, 'y%AzimAvg_Ct (azimuth-averaged ct)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
      
      if ( InitInp%UseSC ) then
         call AllocAry(y%toSC, InitInp%NumCtrl2SC, 'y%toSC (turbine controller outputs to Super Controller)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
      end if
      
      nb = size(m%Turbine%AD%y%BladeLoad)
      Allocate( m%ADRotorDisk(nb), m%TempDisp(nb), m%TempLoads(nb), m%AD_L2L(nb), STAT=ErrStat2 )
      if (ErrStat2 /= 0) then
         call SetErrStat(ErrID_Fatal,"Error allocating space for ADRotorDisk meshes.",ErrStat,ErrMsg,RoutineName)
         call cleanup()
         return
      end if
      
      do k=1,nb
         
         call meshCopy(  SrcMesh         = m%Turbine%AD%y%BladeLoad(k) &
                       , DestMesh        = m%TempDisp(k)         & 
                       , CtrlCode        = MESH_COUSIN           &  ! Like a sibling, except using new memory for position/refOrientation and elements
                       , Orientation     = .TRUE.                &  ! set automatically to identity
                       , TranslationDisp = .TRUE.                &  ! set automatically to 0
                       , ErrStat         = ErrStat2              &
                       , ErrMess         = ErrMsg2               )
            call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
       
         call meshCopy(  SrcMesh         = m%TempDisp(k)         &
                       , DestMesh        = m%TempLoads(k)        & 
                       , CtrlCode        = MESH_SIBLING          &
                       , Force           = .true.                &
                       , Moment          = .true.                &
                       , ErrStat         = ErrStat2              &
                       , ErrMess         = ErrMsg2               )
            call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
                        
            
         call MeshCreate ( BlankMesh         = m%ADRotorDisk(k) &
                          ,IOS               = COMPONENT_OUTPUT &
                          ,Nnodes            = p%nr             &
                          ,ErrStat           = ErrStat2         &
                          ,ErrMess           = ErrMsg2          &
                          ,Force             = .true.           &
                          ,Moment            = .true.           &
                          ,TranslationDisp   = .true.           & ! only for loads transfer
                          ,Orientation       = .true.           & ! only for loads transfer
                         )
               call SetErrStat( errStat2, errMsg2, errStat, errMsg, RoutineName )

            if (errStat >= AbortErrLev) exit
            
            ! set node initial position/orientation
         ! shortcut for 
         ! call MeshPositionNode(m%ADRotorDisk(k), j, [0,0,r(j)], errStat2, errMsg2)
         m%ADRotorDisk(k)%Position(3,:) = p%r ! this will get overwritten later, but we check that we have no zero-length elements in MeshCommit()
         m%ADRotorDisk(k)%TranslationDisp = 0.0_R8Ki ! this happens by default, anyway....
         
            ! create line2 elements
         do j=1,p%nr-1
            call MeshConstructElement( m%ADRotorDisk(k), ELEMENT_LINE2, errStat2, errMsg2, p1=j, p2=j+1 )
               call SetErrStat( errStat2, errMsg2, errStat, errMsg, RoutineName )
         end do !j
            
         call MeshCommit(m%ADRotorDisk(k), errStat2, errMsg2 )
            call SetErrStat( errStat2, errMsg2, errStat, errMsg, RoutineName )
            if (errStat >= AbortErrLev) exit
            
         call MeshMapCreate(m%TempLoads(k), m%ADRotorDisk(k), m%AD_L2L(k), ErrStat2, ErrMsg2) ! this is going to transfer the motions as well as the loads, which is overkill
            call SetErrStat( errStat2, errMsg2, errStat, errMsg, RoutineName )
      end do
      
      !................
      ! also need to set the WrOutput channels...
      !................
      
      
      call cleanup()
      
contains
   subroutine cleanup()
   
      call FAST_DestroyExternInitType(ExternInitData,ErrStat2,ErrMsg2) ! this doesn't actually do anything unless we add allocatable data later
      
   end subroutine cleanup

END SUBROUTINE FWrap_Init
!----------------------------------------------------------------------------------------------------------------------------------
! this routine sets the parameters for the FAST Wrapper module. It does not set p%n_FAST_low because we need to initialize FAST first.
subroutine SetParameters(InitInp, p, dt_FAST, InitInp_dt, ErrStat, ErrMsg)
   TYPE(FWrap_InitInputType),       INTENT(IN   )  :: InitInp     !< Input data for initialization routine
   TYPE(FWrap_ParameterType),       INTENT(INOUT)  :: p           !< Parameters
   REAL(DbKi),                      INTENT(IN   )  :: dt_FAST     !< time step for FAST
   REAL(DbKi),                      INTENT(IN   )  :: InitInp_dt  !< time step for FAST.Farm
   
   INTEGER(IntKi),                  INTENT(  OUT)  :: ErrStat     !< Error status of the operation
   CHARACTER(*),                    INTENT(  OUT)  :: ErrMsg      !< Error message if ErrStat /= ErrID_None

      ! local variables
   TYPE(FAST_ExternInitType)                       :: ExternInitData 
   
   INTEGER(IntKi)                                  :: i           
   INTEGER(IntKi)                                  :: ErrStat2    ! local error status
   CHARACTER(ErrMsgLen)                            :: ErrMsg2     ! local error message
   CHARACTER(*), PARAMETER                         :: RoutineName = 'FWrap_Init'
   
   
   p%p_ref_Turbine = InitInp%p_ref_Turbine  
   p%nr            = InitInp%nr              

   call AllocAry(p%r, p%nr, 'p%r (radial discretization)', ErrStat2, ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)

   if (ErrStat>=AbortErrLev) return
   
   do i=0,p%nr-1
      p%r(i+1) = i*InitInp%dr
   end do
   
   
   ! p%n_FAST_low has to be set AFTER we initialize FAST, because we need to know what the FAST time step is going to be.    
   IF ( EqualRealNos( dt_FAST, InitInp_dt ) ) THEN
      p%n_FAST_low = 1
   ELSE
      IF ( dt_FAST > InitInp_dt ) THEN
         ErrStat = ErrID_Fatal
         ErrMsg = "The FAST time step ("//TRIM(Num2LStr(dt_FAST))// &
                    " s) cannot be larger than FAST.Farm time step ("//TRIM(Num2LStr(InitInp_dt))//" s)."
      ELSE
            ! calculate the number of subcycles:
         p%n_FAST_low = NINT( InitInp_dt / dt_FAST )
            
            ! let's make sure the FAST DT is an exact integer divisor of the global (FAST.Farm) time step:
         IF ( .NOT. EqualRealNos( InitInp_dt, dt_FAST * p%n_FAST_low )  ) THEN
            ErrStat = ErrID_Fatal
            ErrMsg  = "The FASTWrapper module time step ("//TRIM(Num2LStr(dt_FAST))// &
                      " s) must be an integer divisor of the FAST.Farm time step ("//TRIM(Num2LStr(InitInp_dt))//" s)."
         END IF
            
      END IF
   END IF      

   
    
end subroutine SetParameters
!----------------------------------------------------------------------------------------------------------------------------------
!> This routine is called at the end of the simulation.
SUBROUTINE FWrap_End( u, p, x, xd, z, OtherState, y, m, ErrStat, ErrMsg )
!..................................................................................................................................

   TYPE(FWrap_InputType),           INTENT(INOUT)  :: u           !< System inputs
   TYPE(FWrap_ParameterType),       INTENT(INOUT)  :: p           !< Parameters
   TYPE(FWrap_ContinuousStateType), INTENT(INOUT)  :: x           !< Continuous states
   TYPE(FWrap_DiscreteStateType),   INTENT(INOUT)  :: xd          !< Discrete states
   TYPE(FWrap_ConstraintStateType), INTENT(INOUT)  :: z           !< Constraint states
   TYPE(FWrap_OtherStateType),      INTENT(INOUT)  :: OtherState  !< Other states
   TYPE(FWrap_OutputType),          INTENT(INOUT)  :: y           !< System outputs
   TYPE(FWrap_MiscVarType),         INTENT(INOUT)  :: m           !< Misc variables for optimization (not copied in glue code)
   INTEGER(IntKi),                  INTENT(  OUT)  :: ErrStat     !< Error status of the operation
   CHARACTER(*),                    INTENT(  OUT)  :: ErrMsg      !< Error message if ErrStat /= ErrID_None

      ! local variables
   INTEGER(IntKi)                                  :: ErrStat2    ! local error status
   CHARACTER(ErrMsgLen)                            :: ErrMsg2     ! local error message
   CHARACTER(*), PARAMETER                         :: RoutineName = 'FWrap_End'

      ! Initialize ErrStat

   ErrStat = ErrID_None
   ErrMsg  = ''


      !! Place any last minute operations or calculations here:

   CALL ExitThisProgram_T( m%Turbine, ErrID_None, .false. )   

      !! Close files here (but because of checkpoint-restart capability, it is not recommended to have files open during the simulation):


      !! Destroy the input data:

   call FWrap_DestroyInput( u, ErrStat2, ErrMsg2 )
      call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)


      !! Destroy the parameter data:

   call FWrap_DestroyParam( p, ErrStat2, ErrMsg2 )
      call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)

      !! Destroy the state data:

   call FWrap_DestroyContState(   x,          ErrStat2,ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
   call FWrap_DestroyDiscState(   xd,         ErrStat2,ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
   call FWrap_DestroyConstrState( z,          ErrStat2,ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
   call FWrap_DestroyOtherState(  OtherState, ErrStat2,ErrMsg2); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)


      !! Destroy the output data:

   call FWrap_DestroyOutput( y, ErrStat2, ErrMsg2 ); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)

   
      !! Destroy the misc data:

   call FWrap_DestroyMisc( m, ErrStat2, ErrMsg2 ); call SetErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)


END SUBROUTINE FWrap_End
!----------------------------------------------------------------------------------------------------------------------------------
!> This routine updates states and outputs to n+1 based on inputs and states at n (this has an inherent time-step delay on outputs).
!! The routine uses subcycles because FAST typically has a smaller time step than FAST.Farm.
SUBROUTINE FWrap_Increment( t, n, u, p, x, xd, z, OtherState, y, m, ErrStat, ErrMsg )
!..................................................................................................................................

   REAL(DbKi),                       INTENT(IN   ) :: t               !< Current simulation time in seconds
   INTEGER(IntKi),                   INTENT(IN   ) :: n               !< Current step of the simulation: t = n*Interval
   TYPE(FWrap_InputType),            INTENT(INOUT) :: u               !< Inputs at t (not changed, but possibly copied)
   TYPE(FWrap_ParameterType),        INTENT(IN   ) :: p               !< Parameters
   TYPE(FWrap_ContinuousStateType),  INTENT(INOUT) :: x               !< Input: Continuous states at t;
                                                                      !!   Output: Continuous states at t + Interval
   TYPE(FWrap_DiscreteStateType),    INTENT(INOUT) :: xd              !< Input: Discrete states at t;
                                                                      !!   Output: Discrete states at t + Interval
   TYPE(FWrap_ConstraintStateType),  INTENT(INOUT) :: z               !< Input: Constraint states at t;
                                                                      !!   Output: Constraint states at t + Interval
   TYPE(FWrap_OtherStateType),       INTENT(INOUT) :: OtherState      !< Other states: Other states at t;
                                                                      !!   Output: Other states at t + Interval
   TYPE(FWrap_OutputType),          INTENT(INOUT)  :: y               !< Outputs computed at t + Interval (Input only so that mesh con-
                                                                      !!   nectivity information does not have to be recalculated)
   TYPE(FWrap_MiscVarType),          INTENT(INOUT) :: m               !<  Misc variables for optimization (not copied in glue code)
   INTEGER(IntKi),                   INTENT(  OUT) :: ErrStat         !< Error status of the operation
   CHARACTER(*),                     INTENT(  OUT) :: ErrMsg          !< Error message if ErrStat /= ErrID_None

      ! Local variables   
   INTEGER(IntKi)                                  :: n_ss            ! sub-cycle loop
   INTEGER(IntKi)                                  :: n_FAST          ! n for this FAST instance
   
   INTEGER(IntKi)                                  :: ErrStat2        ! local error status
   CHARACTER(ErrMsgLen)                            :: ErrMsg2         ! local error message
   CHARACTER(*), PARAMETER                         :: RoutineName = 'FWrap_Increment'


      ! Initialize variables

   ErrStat   = ErrID_None           ! no error has occurred
   ErrMsg    = ''

   !IF ( n > m%Turbine%p_FAST%n_TMax_m1 - p%n_FAST_low ) THEN !finish 
   !   
   !   call setErrStat(ErrID_Fatal,"programming error: FAST.Farm has exceeded FAST's TMax",ErrStat,ErrMsg,RoutineName)
   !   return
   !   
   !ELSE
   !   
         ! set the inputs needed for FAST
      call FWrap_SetInputs(u, m, t)
      
      ! call FAST p%n_FAST_low times:
      do n_ss = 1, p%n_FAST_low
         n_FAST = n*p%n_FAST_low + n_ss - 1
         
         CALL FAST_Solution_T( t_initial, n_FAST, m%Turbine, ErrStat2, ErrMsg2 )                  
            call setErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
            if (ErrStat >= AbortErrLev) return
            
      end do ! n_ss
      
      call FWrap_CalcOutput(p, u, y, m, ErrStat2, ErrMsg2)
         call setErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
      
   !END IF


END SUBROUTINE FWrap_Increment
!----------------------------------------------------------------------------------------------------------------------------------
!> This routine calculates outputs at n=0 based on inputs at n=0.
SUBROUTINE FWrap_t0( u, p, x, xd, z, OtherState, y, m, ErrStat, ErrMsg )
!..................................................................................................................................

   TYPE(FWrap_InputType),           INTENT(INOUT)  :: u           !< Inputs at t
   TYPE(FWrap_ParameterType),       INTENT(IN   )  :: p           !< Parameters
   TYPE(FWrap_ContinuousStateType), INTENT(IN   )  :: x           !< Continuous states at t
   TYPE(FWrap_DiscreteStateType),   INTENT(IN   )  :: xd          !< Discrete states at t
   TYPE(FWrap_ConstraintStateType), INTENT(IN   )  :: z           !< Constraint states at t
   TYPE(FWrap_OtherStateType),      INTENT(IN   )  :: OtherState  !< Other states at t
   TYPE(FWrap_MiscVarType),         INTENT(INOUT)  :: m           !< Misc variables for optimization (not copied in glue code)
   TYPE(FWrap_OutputType),          INTENT(INOUT)  :: y           !< Outputs computed at t (Input only so that mesh con-
                                                                  !!   nectivity information does not have to be recalculated)
   INTEGER(IntKi),                  INTENT(  OUT)  :: ErrStat     !< Error status of the operation
   CHARACTER(*),                    INTENT(  OUT)  :: ErrMsg      !< Error message if ErrStat /= ErrID_None

   INTEGER(IntKi)                                  :: ErrStat2    ! local error status
   CHARACTER(ErrMsgLen)                            :: ErrMsg2     ! local error message
   CHARACTER(*), PARAMETER                         :: RoutineName = 'FWrap_t0'

      ! Initialize ErrStat

   ErrStat = ErrID_None
   ErrMsg  = ''


      ! set the inputs needed for FAST:
   call FWrap_SetInputs(u, m, 0.0_DbKi)
      
      ! compute the FAST t0 solution:
   call FAST_Solution0_T(m%Turbine, ErrStat2, ErrMsg2 ) 
      call setErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)
      
      ! set the outputs for FAST.Farm:
   call FWrap_CalcOutput(p, u, y, m, ErrStat2, ErrMsg2)
      call setErrStat(ErrStat2,ErrMsg2,ErrStat,ErrMsg,RoutineName)

   
END SUBROUTINE FWrap_t0
!----------------------------------------------------------------------------------------------------------------------------------
!> This subroutine sets the FASTWrapper outputs based on what this instance of FAST computed.
SUBROUTINE FWrap_CalcOutput(p, u, y, m, ErrStat, ErrMsg)

   TYPE(FWrap_ParameterType),       INTENT(IN   )  :: p           !< Parameters
   TYPE(FWrap_InputType),           INTENT(INOUT)  :: u           !< Inputs at t
   TYPE(FWrap_MiscVarType),         INTENT(INOUT)  :: m           !< Misc variables for optimization (not copied in glue code)
   TYPE(FWrap_OutputType),          INTENT(INOUT)  :: y           !< Outputs 
   INTEGER(IntKi),                  INTENT(  OUT)  :: ErrStat     !< Error status of the operation
   CHARACTER(*),                    INTENT(  OUT)  :: ErrMsg      !< Error message if ErrStat /= ErrID_None

      ! Local variables   
   REAL(ReKi)                                      :: vx          ! velocity in x direction
   REAL(ReKi)                                      :: vy          ! velocity in y direction
   REAL(ReKi)                                      :: num         ! numerator
   REAL(ReKi)                                      :: denom       ! denominator
   REAL(ReKi)                                      :: p0(3)       ! hub location (in FAST with 0,0,0 as turbine reference)
   REAL(R8Ki)                                      :: theta(3)    
   REAL(R8Ki)                                      :: orientation(3,3)    
   
   INTEGER(IntKi)                                  :: j, k        ! loop counters
   
   INTEGER(IntKi)                                  :: ErrStat2        ! local error status
   CHARACTER(ErrMsgLen)                            :: ErrMsg2         ! local error message
   CHARACTER(*), PARAMETER                         :: RoutineName = 'FWrap_CalcOutput'
   
   integer, parameter                              :: indx = 1  ! m%BEMT_u(1) is at t; m%BEMT_u(2) is t+dt
   
      ! Initialize ErrStat

   ErrStat = ErrID_None
   ErrMsg  = ''

      ! put this back!
   call move_alloc(m%Turbine%IfW%m%FDext%V, u%Vdist_High)
   
   
   ! Turbine-dependent commands to the super controller:
   if (m%Turbine%p_FAST%UseSC) then
      y%toSC = m%Turbine%SC_DX%u%toSC
   end if
   
   
   ! ....... outputs from AeroDyn v15 ............
   
   ! note that anything that uses m%Turbine%AD%Input(1) assumes we have not updated these inputs after calling AD_CalcOutput in FAST.
   
   ! Orientation of rotor centerline, normal to disk:
   y%xHat_Disk = m%Turbine%AD%Input(1)%HubMotion%Orientation(1,:,1) !actually also x_hat_disk and x_hat_hub
   
   
   ! Nacelle-yaw error i.e. the angle about positive Z^ from the rotor centerline to the rotor-disk-averaged relative wind 
   ! velocity (ambients + deficits + motion), both projected onto the horizontal plane, rad
   
      ! if the orientation of the rotor centerline or rotor-disk-averaged relative wind speed is directed vertically upward or downward (+/-Z^)
      ! the nacelle-yaw error is undefined
   if ( EqualRealNos(m%Turbine%AD%m%V_DiskAvg(1), 0.0_ReKi) .and. EqualRealNos(m%Turbine%AD%m%V_DiskAvg(2), 0.0_ReKi) ) then
      call SetErrStat(ErrID_Fatal,"Nacelle-yaw error is undefined because the rotor-disk-averaged relative wind speed "// &
                        "is directed vertically", ErrStat,ErrMsg,RoutineName) 
   elseif ( EqualRealNos(y%xHat_Disk(1), 0.0_ReKi) .and. EqualRealNos(y%xHat_Disk(2), 0.0_ReKi) ) then
      call SetErrStat(ErrID_Fatal,"Nacelle-yaw error is undefined because the rotor centerline "// &
                        "is directed vertically", ErrStat,ErrMsg,RoutineName) 
   else
      vy = m%Turbine%AD%m%V_DiskAvg(2) * y%xHat_Disk(1) - m%Turbine%AD%m%V_DiskAvg(1) * y%xHat_Disk(2) 
      vx = m%Turbine%AD%m%V_DiskAvg(1) * y%xHat_Disk(1) + m%Turbine%AD%m%V_DiskAvg(2) * y%xHat_Disk(2) 
      
      y%YawErr = atan2(vy, vx)
   end if
   
      
   ! Center position of hub, m
   p0 = m%Turbine%AD%Input(1)%HubMotion%Position(:,1) + m%Turbine%AD%Input(1)%HubMotion%TranslationDisp(:,1) 
   y%p_hub = p%p_ref_Turbine + p0     
   
   ! Rotor diameter, m
   y%D_rotor = 2.0_ReKi * maxval(m%Turbine%AD%m%BEMT_u(indx)%rLocal) ! BEMT_u(indx) is calculated on inputs that were passed INTO AD_CalcOutput; Input(1) is calculated from values passed out of ED_CalcOutput AFTER AD_CalcOutput

   if ( y%D_rotor > p%r(p%nr) ) then
      call SetErrStat(ErrID_Fatal,"The radius of the wake planes is not large relative to the rotor diameter.", ErrStat,ErrMsg,RoutineName) 
   end if
   
   ! Rotor-disk-averaged relative wind speed (ambient + deficits + motion), normal to disk, m/s
   y%DiskAvg_Vx_Rel = m%Turbine%AD%m%V_dot_x
   
   ! Azimuthally averaged thrust force coefficient (normal to disk), distributed radially      
   theta = 0.0_ReKi
   do k=1,size(m%ADRotorDisk)
            
      m%TempDisp(k)%RefOrientation = m%Turbine%AD%Input(1)%BladeMotion(k)%Orientation      
      m%TempDisp(k)%Position       = m%Turbine%AD%Input(1)%BladeMotion(k)%Position + m%Turbine%AD%Input(1)%BladeMotion(k)%TranslationDisp     
     !m%TempDisp(k)%TranslationDisp = 0.0_R8Ki
      m%TempLoads(k)%Force         = m%Turbine%AD%y%BladeLoad(k)%Force
      m%TempLoads(k)%Moment        = m%Turbine%AD%y%BladeLoad(k)%Moment
      
      theta(1) = m%Turbine%AD%m%hub_theta_x_root(k)
      orientation = EulerConstruct( theta )
      m%ADRotorDisk(k)%RefOrientation(:,:,1) = matmul(orientation, m%Turbine%AD%Input(1)%HubMotion%Orientation(:,:,1) )
      do j=1,p%nr
         m%ADRotorDisk(k)%RefOrientation(:,:,j) = m%ADRotorDisk(k)%RefOrientation(:,:,1)
         m%ADRotorDisk(k)%Position(:,j) = p0 + p%r(j)*m%ADRotorDisk(k)%RefOrientation(3,:,1)
      end do
     !m%ADRotorDisk(k)%TranslationDisp = 0.0_ReKi
      m%ADRotorDisk(k)%RemapFlag = .true.
   
      call transfer_line2_to_line2(m%TempLoads(k), m%ADRotorDisk(k), m%AD_L2L(k), ErrStat2, ErrMsg2, m%TempDisp(k), m%ADRotorDisk(k))
         call setErrStat(ErrStat2,ErrMsg2,ErrStat2,ErrMsg,RoutineName)
         if (ErrStat >= AbortErrLev) return
   end do
         
   if (EqualRealNos(y%DiskAvg_Vx_Rel,0.0_ReKi)) then
      y%AzimAvg_Ct = 0.0_ReKi
   else
      y%AzimAvg_Ct(1) = 0.0_ReKi
      
      do j=2,p%nr
         
         num = 0.0_ReKi
         do k=1,size(m%ADRotorDisk)
            num   =  num + dot_product( y%xHat_Disk, m%ADRotorDisk(k)%Force(:,j) )
         end do
         
         denom = m%Turbine%AD%p%AirDens * pi * p%r(j) * y%DiskAvg_Vx_Rel**2
            
         y%AzimAvg_Ct(j) = num / denom
      end do
         
   end if  
      
END SUBROUTINE FWrap_CalcOutput
!----------------------------------------------------------------------------------------------------------------------------------
!> This subroutine sets the inputs needed before calling an instance of FAST
SUBROUTINE FWrap_SetInputs(u, m, t)

   TYPE(FWrap_InputType),           INTENT(INOUT)  :: u           !< Inputs at t
   TYPE(FWrap_MiscVarType),         INTENT(INOUT)  :: m           !< Misc variables for optimization (not copied in glue code)
   REAL(DbKi),                      INTENT(IN   )  :: t           !< current simulation time

   ! set the 4d-wind-inflow input array (a bit of a hack [simplification] so that we don't have large amounts of data copied in multiple data structures):
      call move_alloc(u%Vdist_High, m%Turbine%IfW%m%FDext%V)
      m%Turbine%IfW%m%FDext%TgridStart = t 
      
      ! do something with the inputs from the super-controller:
   if ( m%Turbine%p_FAST%UseSC )  then
      
      if ( associated(m%Turbine%SC_DX%y%fromSCglob) ) then
         m%Turbine%SC_DX%y%fromSCglob = u%fromSCglob   ! Yes, we set the inputs of FWrap to the 'outputs' of the SC_DX object, GJH
      end if

      if ( associated(m%Turbine%SC_DX%y%fromSC) ) then
         m%Turbine%SC_DX%y%fromSC     = u%fromSC       ! Yes, we set the inputs of FWrap to the 'outputs' of the SC_DX object, GJH
      end if

   end if   
   
END SUBROUTINE FWrap_SetInputs
!----------------------------------------------------------------------------------------------------------------------------------
END MODULE FASTWrapper
!**********************************************************************************************************************************
