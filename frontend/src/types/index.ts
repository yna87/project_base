export interface Project {
  id: number;
  name: string;
  startDate: string;
  endDate: string;
  phases: {
    planning: Phase;
    design: Phase;
    development: Phase;
    testing: Phase;
  };
}

export interface Phase {
  startDate: string;
  endDate: string;
  status: 'notStarted' | 'inProgress' | 'completed';
}

export interface Task {
  id: number;
  title: string;
  projectId: number;
  phaseType: 'planning' | 'design' | 'development' | 'testing';
  status: 'incomplete' | 'complete';
}

export type PhaseType = 'planning' | 'design' | 'development' | 'testing';
